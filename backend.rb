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

end
helpers BackendHelpers



before /^\/api\// do
  redirect to('/auth/failure') unless authenticated?
end



# URLs for test and debug

get '/' do
  'Hello World!'
end


get '/debug' do
  require 'pry'
  binding.pry

  'Done.'
end



# Authentication & Session management

post '/auth/developer/callback' do
  session[:uid] = env['omniauth.auth']['uid']
  session[:user_name] = env['omniauth.auth']['info']['name']
  session[:user_email] = env['omniauth.auth']['info']['email']

  json(status: 'ok')
end


get '/auth/failure' do
  [ 403, json(status: 'forbidden') ]
end



# Generic RESTful API

get '/api/:model' do |model|
  content_type :json

  result = []
  collection = $db[model]
  collection.find({ owner: session[:uid] }).each do |document|
    id = document['_id']
    document.delete '_id'
    document['id'] = id.to_s
    result << document
  end

  json result
end


get '/api/:model/:id' do |model,id|
  content_type :json

  collection = $db[model]
  document = collection.find_one({ owner: session[:uid], _id: BSON::ObjectId(id) })
  document['id'] = document['_id'].to_s
  document.delete '_id'

  json document
end


post '/api/:model' do |model|
  content_type :json

  json = JSON.parse(request.body.read)
  json['owner'] = session[:uid]

  collection = $db[model]
  id = collection.insert(json)

  json( id: id.to_s )
end


put '/api/:model/:id' do |model,id|
  content_type :json

  json = JSON.parse(request.body.read)
  json['owner'] = session[:uid]

  collection = $db[model]
  collection.update({ owner: session[:uid], _id: BSON::ObjectId(id) }, json)

  json(id: id.to_s )
end


patch '/api/:model/:id' do |model, id|
  content_type :json

  json = JSON.parse(request.body.read)
  json['owner'] = session[:uid]

  collection = $db[model]
  collection.update({ owner: session[:uid], _id: BSON::ObjectId(id) }, { '$set' => json })

  json(id: id.to_s)
end


delete '/api/:model/:id' do |model,id|
  content_type :json

  collection = $db[model]
  collection.remove({ owner: session[:uid], _id: BSON::ObjectId(id) }, { limit: 1 })

  json(status: 'ok')
end


post '/api/:model/find' do |model|
  content_type :json

  json = JSON.parse(request.body.read)
  json['owner'] = session[:uid]
  
  result = []
  collection = $db[model]
  collection.find(json).each do |document|
    id = document['_id']
    document.delete '_id'
    document['id'] = id.to_s
    result << document
  end

  json result
end

