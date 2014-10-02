require 'bundler'
Bundler.require

require 'sinatra/reloader' if development?



$mongo = Mongo::MongoClient.new
$db = $mongo['app']

$reserved_keys = [ '_id', '_owner' ]



class ReservedKeyError < Exception; end
class ObjectDoesNotExist < Exception; end
class MultipleMatch < Exception; end



# FIXME: put this in external YAML configuration
# FIXME: ... and randomize the secret!
configure do
  enable :sessions unless test?
  use Rack::Session::Cookie, secret: 'secret'
  use OmniAuth::Strategies::Developer
end



module BackendHelpers

  def authenticated?
    !session[:uid].nil?
  end

  def current_user
    session[:uid]
  end

  def user_roles
    session[:roles] ||= [ current_user ]
  end

  def collection
    $db[params[:model]]
  end

  def authorization(predicates = {})
    predicates.merge({ _owner: session[:uid] })
  end

  def authorization_predicates(required_permissions = [])
    { '$or' => [ { _owner: current_user },
                 { _tags: 
                   { '$elemMatch' =>
                     { _target: 
                       { '$elemMatch' =>
                         { '$eq' => current_user }
                       },
                       _permissions:
                       { '$all' => required_permissions }
                     }
                   }
                 }
               ]
    }
  end

  def selection_predicates(predicates = nil, required_permissions = [{ _read: true }])
    if predicates
      check_reserved_keys(predicates)
      { '$and' =>
        [ authorization_predicates(required_permissions),
          predicates
        ]
      }
    else
      authorization_predicates(required_permissions)
    end
  end

  def insertion_attributes(attributes = {})
    attributes.merge(authorization)
  end

  def update_attributes(attributes = {})
    attributes.merge(authorization)
  end

  def list
    result = collection.find(selection_predicates)
    clean_result(result)
  end

  def retrieve(id)
    result = collection.find_one(selection_predicates( { _id: BSON::ObjectId(id) } ))
    clean_result(result)
  end

  def create(attributes)
    check_reserved_keys(attributes)
    id = collection.insert(insertion_attributes(attributes))
    id.to_s
  end

  def update(id, attributes)
    check_reserved_keys(attributes)
    result = collection.update(selection_predicates({ _id: BSON::ObjectId(id) }, [ {_read: true}, {_write: true} ]), update_attributes(attributes))
    check_update(result, id)
  end

  def patch(id, attributes)
    check_reserved_keys(attributes)
    result = collection.update(selection_predicates({ _id: BSON::ObjectId(id) }, [ {_read: true}, {_write: true} ]), { '$set' => update_attributes(attributes) })
    check_update(result, id)
  end

  def delete(id)
    result = collection.remove(selection_predicates({ _id: BSON::ObjectId(id) }, [ {_read: true}, {_write: true} ]), { limit: 1 })
    check_delete(result, id)
  end

  def search(predicates)
    check_reserved_keys(predicates)
    result = collection.find(selection_predicates(predicates))
    clean_result(result)
  end

  def check_reserved_keys(hash)
    $reserved_keys.each do |key|
      if hash.has_key? key
        raise ReservedKeyError.new("You can not choose or modify '#{key}' field.")
      end
    end
  end

  def check_update(result, id = '<unknown>')
    if result['ok'] != 1 or result['n'] != 1
      raise ObjectDoesNotExist.new "Object with _id #{id} does not exist."
    end
  end

  def check_delete(result, id = '<unknown>')
    if result['ok'] != 1 or result['n'] != 1
      raise ObjectDoesNotExist.new "Object with _id #{id} does not exist."
    end
  end

  def clean_tags(result)
    result['_tags'].delete_if { |tag| (user_roles & tag['_target']).empty? }
    result['_tags'].each do |tag|
      tag['_target'].select! { |target| user_roles.include?(target) }
    end
  end

  def clean_one_result(result)
    result['_id'] = result['_id'].to_s
    if current_user != result['_owner'] and result['_tags']
      clean_tags(result)
    end
    result
  end

  def clean_result(result)
    if result.is_a?(Mongo::Cursor)
      old_result = result
      result = []
      old_result.each { |one_result| result << clean_one_result(one_result) }
    elsif result.is_a?(Array)
      result.each { |one_result| clean_one_result(one_result) }
    elsif result.is_a?(BSON::OrderedHash)
      clean_one_result(result)
    elsif result.nil?
      # new_result = nil      
    else
      raise 'Unhandled Mongo DB result type !'
    end
    result
  end

end
helpers BackendHelpers



error ReservedKeyError do
  [ 422, 'Unprocessable Entity' ]
end

error ObjectDoesNotExist do
  [ 422, 'Unprocessable Entity' ]
end

error do
  [ 500, 'Internal Server Error' ]
end

not_found do
  [ 404, 'Not Found' ]
end

before /^\/api\// do
  redirect to('/auth/failure') unless authenticated?
end



# URLs for test and debug

get '/', provides: :html do
  '<html><body>
     <h1>Hello World!</h1>
   </html></body>' 
end


get '/', provides: :txt do
  'Hello World!'
end


get '/', provides: :json do
  json( status: 'Hello World!' )
end


if development?
  get '/debug' do
    require 'pry'
    binding.pry

    'Done.'
  end
end



# Authentication & Session management

post '/auth/developer/callback', provides: :json do
  session[:uid] = env['omniauth.auth']['uid']
  session[:user_name] = env['omniauth.auth']['info']['name']
  session[:user_email] = env['omniauth.auth']['info']['email']

  json(status: 'ok')
end


get '/auth/failure', provides: :json do
  [ 403, json(status: 'forbidden') ]
end



# Generic RESTful API

get '/api/:model', provides: :json do |model|
  json list
end


get '/api/:model/:id', provides: :json do |model,id|
  json retrieve(id)
end


post '/api/:model', provides: :json do |model|
  begin
    json = JSON.parse(request.body.read)
    id = create(json)
    json( id: id )
  rescue ReservedKeyError => e
    [ 422, json( status: 'Unprocessable Entity', message: e.message )]
  end
end


put '/api/:model/:id', provides: :json do |model,id|
  begin
    json = JSON.parse(request.body.read)
    update(id, json)
    json( status: 'ok' )
  rescue ReservedKeyError, ObjectDoesNotExist => e
    [ 422, json( status: 'Unprocessable Entity', message: e.message )]
  end
end


patch '/api/:model/:id', provides: :json do |model, id|
  begin
    json = JSON.parse(request.body.read)
    patch(id, json)
    json( status: 'ok' )
  rescue ReservedKeyError, ObjectDoesNotExist => e
    [ 422, json( status: 'Unprocessable Entity', message: e.message )]
  end
end


delete '/api/:model/:id', provides: :json do |model,id|
  begin
    delete(id)
    json(status: 'ok')
  rescue ReservedKeyError, ObjectDoesNotExist => e
    [ 422, json( status: 'Unprocessable Entity', message: e.message )]
  end
end


post '/api/:model/search', provides: :json do |model|
  begin
    json = JSON.parse(request.body.read)
    result = search(json)
    json clean_result(result)
  rescue ReservedKeyError => e
    [ 422, json( status: 'Unprocessable Entity', message: e.message )]
  end
end


