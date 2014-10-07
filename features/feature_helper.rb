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

$tom_auth_hash = { 
  "provider"=>"developer",
  "uid"=>"tom@cat.com",
  "info"=>{"name"=>"Tom",
    "email"=>"tom@cat.com"},
  "credentials"=>{}, "extra"=>{}
}

$nobody_auth_hash = { 
  "provider"=>"developer",
  "uid"=>"nobody@nowhere.com",
  "info"=>{"name"=>"Nobody",
    "email"=>"nobody@nowhere.com"},
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

def authenticate_as_tom
  OmniAuth.config.add_mock :developer, $tom_auth_hash
  post('/auth/developer/callback')
end

def authenticate_as_nobody
  OmniAuth.config.add_mock :developer, $nobody_auth_hash
  post('/auth/developer/callback')
end

def parse(json_string)
  MultiJson.load(json_string)
end

def last_json
  last_response.body
end

def typify(arg)
  result = arg

  # ... cascading cast ordered by logical priority (as needed only) ...

  if arg.empty?
    result = nil
  elsif arg == 'true'
    result = true
  elsif arg == 'false'
    result = false
  else
    begin
      result = Integer(arg)
    rescue ArgumentError
      # failed to parse Integer
      begin
        result = parse(arg)
      rescue MultiJson::ParseError
        # failed to parse JSON
      end
    end
  end
  result
end

