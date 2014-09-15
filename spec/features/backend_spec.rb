require File.expand_path('../../feature_spec_helper', __FILE__)



RSpec.describe 'Hello', hello: true do

  specify 'Says Hello World!' do
    header 'Accept', 'text/plain'
    get '/'

    expect(last_response).to be_ok
    expect(last_response.body).to eq('Hello World!')
  end
  
end



RSpec.describe 'Authentication', authentication: true do
  
  specify 'Unauthenticated API access is forbidden' do
    get '/api/people'
    follow_redirect!

    expect(last_response.status).to be 403
    expect(parse(last_response.body)['status']).to eq('forbidden')
  end

  specify 'Authentication success' do
    post('/auth/developer/callback', params: { name: 'Bob', email: 'bob@yankee.com' })

    expect(last_response).to be_ok
    expect(parse(last_response.body)['status']).to eq('ok')
  end
  
  specify 'Authenticated API access success' do
    authenticate_as_bob
    get '/api/people'

    expect(last_response).to be_ok
  end

end



RSpec.describe 'RESTfulness', restfulness: true do

  specify 'Adding one person' do
    authenticate_as_bob
    id = add_homer

    expect(last_response).to be_ok
    expect(id).to be_truthy
  end

  specify 'Retrieving one person' do
    authenticate_as_bob
    id = add_homer
    get "/api/people/#{id}"

    expect(last_response).to be_ok
    expect(parse_and_clean(last_response.body)).to eq(homer)
  end

  specify 'Replacing Homer by Marge' do
    authenticate_as_bob
    id = add_homer
    put("/api/people/#{id}", marge.to_json, { 'CONTENT_TYPE' => 'application/json' })

    expect(last_response).to be_ok
    expect(parse(last_response.body)['id']).to eq(id)

    get "/api/people/#{id}"

    expect(last_response).to be_ok
    expect(parse_and_clean(last_response.body)).to eq(marge)
  end

  specify 'Mutating Homer' do
    authenticate_as_bob
    id = add_homer
    patch("/api/people/#{id}", homer_patch.to_json, { 'CONTENT_TYPE' => 'application/json' })

    expect(last_response).to be_ok
    expect(parse(last_response.body)['id']).to eq(id)

    get "/api/people/#{id}"

    expect(last_response).to be_ok
    expect(parse_and_clean(last_response.body)).to eq(homer.merge(homer_patch))
  end

  specify 'Deleting Homer' do
    authenticate_as_bob
    id = add_homer
    delete "/api/people/#{id}"

    expect(last_response).to be_ok
    expect(parse(last_response.body)['status']).to eq('ok')

    get "/api/people/#{id}"
    expect(last_response.body).to eq('null')
  end

  specify 'Fetching people list' do
    authenticate_as_bob
    get '/api/people'

    expect(last_response).to be_ok
    expect(parse(last_response.body).class).to be Array
  end

end



RSpec.describe 'Search API', search: true do 
  
  specify 'Finding people' do
    authenticate_as_bob
    post('/api/people/find', { 'birthdate' => { '$lt' => '1955-01-01' } }.to_json, { 'CONTENT_TYPE' => 'application/json' })

    expect(last_response).to be_ok
    result = parse(last_response.body)
    expect(result.class).to be Array
    result.each do |person|
      expect(person['birthdate']).to be <= '1955-01-01'
    end
  end
  
end



RSpec.describe 'Access control', access_control: true do

  specify 'Bob can access his data only' do
    authenticate_as_bob

    get '/api/people'

    expect(last_response).to be_ok
    result = parse(last_response.body)
    expect(result.class).to be Array
    result.each do |person|
      expect(person['owner']).to eq($bob_auth_hash['uid'])
    end
  end

  specify 'John can not access Bob data' do
    authenticate_as_bob
    id = add_homer

    authenticate_as_john

    get "/api/people/#{id}"

    expect(last_response.body).to eq('null')

    post('/api/people/find', { owner: $bob_auth_hash['uid'] }.to_json, { 'CONTENT_TYPE' => 'application/json' })

    expect(last_response).to be_ok
    result = parse(last_response.body)
    expect(result.class).to be Array
    result.each do |person|
      expect(person['owner']).not_to eq($bob_auth_hash['uid'])
    end
  end

end


