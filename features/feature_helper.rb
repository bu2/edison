$mongo = Mongo::MongoClient.new
$db = $mongo['app']

$bob_auth_hash = { 
  "provider"=>"developer",
  "uid"=>"bob@sponge.com",
  "info"=>{"name"=>"Bob",
    "email"=>"bob@sponge.com"},
  "credentials"=>{}, "extra"=>{}
}

$john_auth_hash = { 
  "provider"=>"developer",
  "uid"=>"john@doe.com",
  "info"=>{"name"=>"John",
    "email"=>"john@doe.com"},
  "credentials"=>{}, "extra"=>{}
}



def app
  Sinatra::Application
end

def authenticate_as_bob
  OmniAuth.config.add_mock :developer, $bob_auth_hash
  post('/auth/developer/callback')
end

def authenticate_as_john
  OmniAuth.config.add_mock :developer, $john_auth_hash
  post('/auth/developer/callback')
end

def parse(json_string)
  MultiJson.load(json_string)
end

def last_json
  last_response.body
end
