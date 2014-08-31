require 'bundler'
Bundler.require

require 'sinatra/reloader' if development?



$mongo = Mongo::MongoClient.new
$db = $mongo['app']



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

  def collection
    $db[params[:model]]
  end

  def authorization(predicates = {})
    predicates.merge({ owner: session[:uid] })
  end

  def selection_predicates(predicates = {})
    predicates.merge(authorization)
  end

  def insertion_attributes(predicates = {})
    predicates.merge(authorization)
  end

  def update_attributes(predicates = {})
    predicates.merge(authorization)
  end

  def clean_one_result(result)
    result['id'] = result['_id'].to_s
    result.delete '_id'
    result
  end

  def clean_result(result)
    new_result = nil
    if result.is_a? Mongo::Cursor
      new_result = []
      result.each { |one_result| new_result << clean_one_result(one_result) }
    elsif result.is_a? BSON::OrderedHash
      new_result = clean_one_result(result)
    elsif result.nil?
      # new_result = nil      
    else
      raise 'Unhandled Mongo DB result type !'
    end
    new_result
  end

end
helpers BackendHelpers



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
  result = collection.find(selection_predicates)
  json clean_result(result)
end


get '/api/:model/:id', provides: :json do |model,id|
  result = collection.find_one(selection_predicates({ _id: BSON::ObjectId(id) }))
  json clean_result(result)
end


post '/api/:model', provides: :json do |model|
  json = JSON.parse(request.body.read)
  id = collection.insert(insertion_attributes(json))
  json( id: id.to_s )
end


put '/api/:model/:id', provides: :json do |model,id|
  json = JSON.parse(request.body.read)
  collection.update(selection_predicates({ _id: BSON::ObjectId(id) }), update_attributes(json))
  json( id: id.to_s )
end


patch '/api/:model/:id', provides: :json do |model, id|
  json = JSON.parse(request.body.read)
  collection.update(selection_predicates({ _id: BSON::ObjectId(id) }), { '$set' => update_attributes(json) })
  json( id: id.to_s )
end


delete '/api/:model/:id', provides: :json do |model,id|
  collection.remove(selection_predicates({ _id: BSON::ObjectId(id) }), { limit: 1 })
  json(status: 'ok')
end


post '/api/:model/find', provides: :json do |model|
  json = JSON.parse(request.body.read)
  result = collection.find(selection_predicates(json))
  json clean_result(result)
end


