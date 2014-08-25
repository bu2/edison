require 'bundler'
Bundler.require

require 'sinatra/reloader' if development?



$mongo = Mongo::MongoClient.new
$db = $mongo['app']



get '/' do
  'Hello World!'
end


get '/api/:model' do |model|
  content_type :json

  result = []
  collection = $db[model]
  collection.find.each do |document|
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
  document = collection.find_one({ _id: BSON::ObjectId(id) })
  document['id'] = document['_id'].to_s
  document.delete '_id'

  json document
end


post '/api/:model' do |model|
  content_type :json

  json = JSON.parse(request.body.read)

  collection = $db[model]
  id = collection.insert(json)

  json( id: id.to_s )
end


put '/api/:model/:id' do |model,id|
  content_type :json

  json = JSON.parse(request.body.read)

  collection = $db[model]
  collection.update({ _id: BSON::ObjectId(id) }, json)

  json(id: id.to_s )
end

