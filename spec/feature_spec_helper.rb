require 'spec_helper'

require 'rack/test'

require File.expand_path('../../backend', __FILE__)



$bob_auth_hash = { 
  "provider"=>"developer",
  "uid"=>"bob@yankee.com",
  "info"=>{"name"=>"Bob",
    "email"=>"bob@yankee.com"},
  "credentials"=>{}, "extra"=>{}
}

$john_auth_hash = { 
  "provider"=>"developer",
  "uid"=>"john@doe.com",
  "info"=>{"name"=>"John",
    "email"=>"john@doe.com"},
  "credentials"=>{}, "extra"=>{}
}

OmniAuth.config.test_mode = true



include Rack::Test::Methods

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

def homer
  { 'firstname' => 'Homer', 'lastname' => 'Simpson', 'birthdate' => '1953-05-12' }
end

def homer_patch
  { 'firstname' => '|-|0/\/\3R', 'lastname' => '$1/\/\P50|\|', 'mode' => 'L337 5P34|<' }
end

def marge
  { 'firstname' => 'Marge', 'lastname' => 'Simpson', 'birthdate' => '1959-06-29' }
end

def add_homer
  post('/api/people', homer.to_json, { 'CONTENT_TYPE' => 'application/json' })
  JSON.parse(last_response.body)['id']
end

def parse(json_string)
  JSON.parse(json_string)
end

def clean(json)
  json.delete('id')
  json.delete('owner')
  json
end

def parse_and_clean(json_string)
  clean(parse(json_string))
end
