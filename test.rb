ENV['RACK_ENV'] = 'test'

require 'test/unit'
require 'rack/test'
require 'json'

require './backend'



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



class BackendTest < Test::Unit::TestCase

  # Test Helpers

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

  def parse_and_clean(json_string)
    result = parse(json_string)
    result.delete('id')
    result.delete('owner')
    result
  end


  
  # Hello test

  def test_it_says_hello_world
    header 'Accept', 'text/plain'
    get '/'

    assert last_response.ok?
    assert_equal 'Hello World!', last_response.body
  end



  # Functional tests

  def test_unauthenticated_api_access_forbidden
    get '/api/people'
    follow_redirect!

    assert_equal 403, last_response.status
    assert_equal 'forbidden', JSON.parse(last_response.body)['status']
  end



  def test_authentication_success
    post('/auth/developer/callback', params: { name: 'Bob', email: 'bob@yankee.com' })

    assert last_response.ok?
    assert_equal 'ok', JSON.parse(last_response.body)['status']
  end



  def test_authenticated_api_access_success
    authenticate_as_bob
    get '/api/people'

    assert last_response.ok?
  end



  def test_adding_one_person
    authenticate_as_bob
    id = add_homer

    assert last_response.ok?
    assert !id.nil?
  end



  def test_retrieving_one_person
    authenticate_as_bob
    id = add_homer
    get "/api/people/#{id}"

    assert last_response.ok?
    result = parse_and_clean(last_response.body)
    assert_equal homer, result
  end



  def test_replacing_homer_by_marge
    authenticate_as_bob
    id = add_homer
    put("/api/people/#{id}", marge.to_json, { 'CONTENT_TYPE' => 'application/json' })

    assert last_response.ok?
    assert_equal id, JSON.parse(last_response.body)['id']

    get "/api/people/#{id}"

    assert last_response.ok?
    result = parse_and_clean(last_response.body)
    assert_equal marge, result
  end



  def test_mutating_homer
    authenticate_as_bob
    id = add_homer
    patch("/api/people/#{id}", homer_patch.to_json, { 'CONTENT_TYPE' => 'application/json' })

    assert last_response.ok?
    assert_equal id, JSON.parse(last_response.body)['id']

    get "/api/people/#{id}"

    assert last_response.ok?
    result = parse_and_clean(last_response.body)
    assert_equal homer.merge(homer_patch), result
  end



  def test_deleting_homer
    authenticate_as_bob
    id = add_homer
    delete "/api/people/#{id}"

    assert last_response.ok?
    assert_equal 'ok', JSON.parse(last_response.body)['status']

    get "/api/people/#{id}"
    assert_equal 'null', last_response.body
  end



  def test_fetching_people_list
    authenticate_as_bob
    get '/api/people'

    assert last_response.ok?
    assert_equal Array, JSON.parse(last_response.body).class
  end



  def test_finding_people
    authenticate_as_bob
    post('/api/people/find', { 'birthdate' => { '$lt' => '1955-01-01' } }.to_json, { 'CONTENT_TYPE' => 'application/json' })

    assert last_response.ok?
    result = parse(last_response.body)
    assert_equal Array, result.class
    result.each do |person|
      assert person['birthdate'] <= '1955-01-01'
    end
  end



  def test_bob_access_his_data_only
    authenticate_as_bob

    get '/api/people'

    assert last_response.ok?
    result = parse(last_response.body)
    assert_equal Array, result.class
    result.each do |person|
      assert_equal $bob_auth_hash['uid'], person['owner']
    end
  end

  

  def test_john_cant_access_bob_data
    authenticate_as_bob
    id = add_homer

    authenticate_as_john

    get "/api/people/#{id}"
    assert_equal 'null', last_response.body

    post('/api/people/find', { owner: $bob_auth_hash['uid'] }.to_json, { 'CONTENT_TYPE' => 'application/json' })

    assert last_response.ok?
    result = parse(last_response.body)
    assert_equal Array, result.class
    result.each do |person|
      assert person['owner'] != $bob_auth_hash['uid']
    end
  end

end


