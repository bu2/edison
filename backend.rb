require 'bundler'
Bundler.require

require 'sinatra/reloader' if development?

require 'set'
require 'uri'



def heroku?
  Sinatra::Application.environment == :heroku
end

def get_connection
  if heroku?
    return @db_connection if @db_connection
    db = URI.parse(ENV['MONGOHQ_URL'])
    db_name = db.path.gsub(/^\//, '')
    @db_connection = Mongo::Connection.new(db.host, db.port).db(db_name) 
    @db_connection.authenticate(db.user, db.password) unless (db.user.nil? || db.user.nil?)
    @db_connection
  else
    @mongo ||= Mongo::MongoClient.new
    @db ||= @mongo['app']
  end
end



RESERVED_KEYS = [ '_id', '_owner', '_tags' ]



class LoginError < Exception; end
class ForbiddenError < Exception; end
class ReservedKeyError < Exception; end
class InvalidTagError < Exception; end
class ObjectNotFoundError < Exception; end
class LockError < Exception; end



configure do
  use Rack::Session::Mongo, get_connection
  use OmniAuth::Strategies::Developer unless production?
end



module BackendHelpers

  def login
    strategy = params[:strategy]
    if strategy != 'developer'
      query_key = "#{strategy}.uid"
      auth = env['omniauth.auth']
      uid = auth[:uid]
      user = parse({ strategy => auth }.to_json)
    
      result = get_connection['_users'].find_and_modify( { query: { query_key => uid },
                                                           update: { '$set' => user },
                                                           upsert: true,
                                                           new: true } )
      check_login(result)
      session[:uid] = result['_id'].to_s
    else
      session[:uid] = env['omniauth.auth']['uid']
    end
  end

  def authenticated?
    !session[:uid].nil?
  end

  def current_user
    session[:uid]
  end

  def public_role
    'public'
  end

  def user_roles
    [ current_user, public_role ]
  end

  def collection
    get_connection[params[:model]]
  end

  def authorization(predicates = {})
    predicates.merge({ _owner: session[:uid] })
  end

  def authorization_predicates(required_permissions = [])
    { '$or' => [ { _owner: current_user },
                 { _tags: 
                   { '$elemMatch' =>
                     { _targets: 
                       { '$in' => user_roles },
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
    attributes.merge({ _owner: current_user })
  end

  def patch_attributes(attributes = {})
    attributes
  end

  def list
    result = collection.find(selection_predicates)
    clean_result(result)
  end

  def retrieve(id)
    result = collection.find_one(selection_predicates( { _id: BSON::ObjectId(id) } ))
    check_retrieve(result, id)
    clean_result(result)
  end

  def create(attributes)
    check_reserved_keys(attributes)
    id = collection.insert(insertion_attributes(attributes))
    id.to_s
  end

  def update(id, attributes)
    check_reserved_keys(attributes)
    result = collection.update(selection_predicates({ _id: BSON::ObjectId(id) }, []), update_attributes(attributes))
    check_update(result, id)
  end

  def patch(id, attributes)
    check_reserved_keys(attributes)
    result = collection.update(selection_predicates({ '$and' => [ _id: BSON::ObjectId(id), '$or' => [{_lock: {'$exists'=>false}}, {_lock: current_user}, {_lock: false}] ] }, [ {_read: true}, {_write: true} ]), { '$set' => patch_attributes(attributes) })
    check_update(result, id)
  end

  def delete(id)
    result = collection.remove(selection_predicates({ _id: BSON::ObjectId(id) }, []), { limit: 1 })
    check_delete(result, id)
  end

  def search(predicates)
    check_reserved_keys(predicates)
    result = collection.find(selection_predicates(predicates))
    clean_result(result)
  end

  def share(id, tags)
    check_ownership(id)
    check_tags(tags)
    result = collection.update(selection_predicates({ _id: BSON::ObjectId(id) }), { '$set' => patch_attributes({ _tags: tags }) })
    check_update(result, id)
  end

  def lock(id)
    result = collection.update(selection_predicates({ '$and' => [ _id: BSON::ObjectId(id), '$or' => [{_lock: {'$exists'=>false}}, {_lock: false}] ] }, [ {_read: true}, {_write: true} ]), { '$set' => patch_attributes({ _lock: current_user }) })
    check_lock(result, id)
    result = collection.find_one(selection_predicates( { _id: BSON::ObjectId(id) } ))
    check_retrieve(result, id)
    clean_result(result)
  end

  def check_login(result)
    raise LoginError.new 'Failed to log in.' if result.nil?
  end

  def check_reserved_keys(hash)
    RESERVED_KEYS.each do |key|
      if hash.has_key? key
        raise ReservedKeyError.new("You can not choose or modify '#{key}' field.")
      end
    end
  end

  def check_ownership(id = '<unknown>')
    result = retrieve(id)
    raise ForbiddenError.new("You can not grant permissions on this object with _id #{id}.") unless result['_owner'] == current_user
  end

  def check_tags(tags)
    raise InvalidTagError.new unless tags.is_a?(Array)
    tags.each do |tag|
      raise InvalidTagError.new unless tag.is_a?(Hash)
      raise InvalidTagError.new unless tag.keys == [ '_targets', '_permissions' ]
      raise InvalidTagError.new unless tag['_targets'].is_a?(Array)
      raise InvalidTagError.new unless tag['_permissions'].is_a?(Array)
      permission_keys = []
      permission_values = []
      tag['_permissions'].each do |permission|
        raise InvalidTagError.new unless permission.size == 1
        temp = permission.first
        permission_keys << temp[0]
        permission_values << temp[1]
      end
      raise InvalidTagError.new unless Set.new(permission_keys) <= Set.new([ '_read', '_write' ])
      raise InvalidTagError.new unless Set.new(permission_values) <= Set.new([ true, false ])
    end
  end

  def check_retrieve(result, id = '<unknown>')
    if result.nil?
      raise ObjectNotFoundError.new "Object with _id #{id} not found."
    end
  end

  def check_update(result, id = '<unknown>')
    if result['ok'] != 1 or result['n'] != 1
      raise ObjectNotFoundError.new "Object with _id #{id} not found."
    end
  end

  def check_lock(result, id = '<unknown>')
    if result['ok'] != 1 or result['n'] != 1
      raise LockError.new "Failed to acquire lock on object with _id #{id}."
    end
  end

  def check_delete(result, id = '<unknown>')
    if result['ok'] != 1 or result['n'] != 1
      raise ObjectNotFoundError.new "Object with _id #{id} not found."
    end
  end

  def parse(string)
    MultiJson.load(string)
  end

  def clean_tags(result)
    result['_tags'].delete_if { |tag| (user_roles & tag['_targets']).empty? }
    result['_tags'].each do |tag|
      tag['_targets'].select! { |target| user_roles.include?(target) }
    end
  end

  def clean_lock(result)
    if result['_lock'] and result['_lock'] != current_user
      result['_lock'] = true
    end
  end

  def clean_one_result(result)
    result['_id'] = result['_id'].to_s
    if current_user != result['_owner']
      clean_tags(result) if result['_tags']
      clean_lock(result)
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

error InvalidTagError do
  [ 422, 'Unprocessable Entity' ]
end

error ObjectNotFoundError do
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

get '/auth/:strategy/callback', provides: :json do |strategy|
  begin
    login
    json( status: 'ok' )
  rescue LoginError => e
    [ 422, json( status: 'Unprocessable Entity', message: e.message )]
  end
end


post '/auth/:strategy/callback', provides: :json do |strategy|
  begin
    login
    json( status: 'ok' )
  rescue LoginError => e
    [ 422, json( status: 'Unprocessable Entity', message: e.message )]
  end
end


get '/auth/failure', provides: :json do
  [ 403, json(status: 'forbidden') ]
end



# Generic RESTful API

get '/api/:model', provides: :json do |model|
  json list
end


get '/api/:model/:id', provides: :json do |model,id|
  begin
    json retrieve(id)
  rescue ObjectNotFoundError => e
    [ 422, json( status: 'Unprocessable Entity', message: e.message )]
  end
end


post '/api/:model', provides: :json do |model|
  begin
    json = parse(request.body.read)
    id = create(json)
    json( id: id )
  rescue ReservedKeyError => e
    [ 422, json( status: 'Unprocessable Entity', message: e.message )]
  end
end


put '/api/:model/:id', provides: :json do |model,id|
  begin
    json = parse(request.body.read)
    update(id, json)
    json( status: 'ok' )
  rescue ReservedKeyError, ObjectNotFoundError => e
    [ 422, json( status: 'Unprocessable Entity', message: e.message )]
  end
end


patch '/api/:model/:id', provides: :json do |model, id|
  begin
    json = parse(request.body.read)
    patch(id, json)
    json( status: 'ok' )
  rescue ReservedKeyError, ObjectNotFoundError => e
    [ 422, json( status: 'Unprocessable Entity', message: e.message )]
  end
end


delete '/api/:model/:id', provides: :json do |model,id|
  begin
    delete(id)
    json(status: 'ok')
  rescue ReservedKeyError, ObjectNotFoundError => e
    [ 422, json( status: 'Unprocessable Entity', message: e.message )]
  end
end


post '/api/:model/search', provides: :json do |model|
  begin
    json = parse(request.body.read)
    json search(json)
  rescue ReservedKeyError => e
    [ 422, json( status: 'Unprocessable Entity', message: e.message )]
  end
end


post '/api/:model/:id/share', provides: :json do |model, id|
  begin
    json = parse(request.body.read)
    share(id, json)
    json(status: 'ok')
  rescue ForbiddenError, ObjectNotFoundError => e
    [ 422, json( status: 'Unprocessable Entity', message: e.message )]
  end
end


post '/api/:model/:id/lock', provides: :json do |model, id|
  begin
    json lock(id)
  rescue LockError, ObjectNotFoundError => e
    [ 422, json( status: 'Unprocessable Entity', message: e.message )]
  end
end

