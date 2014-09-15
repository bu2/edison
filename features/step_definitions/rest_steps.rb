require File.expand_path '../../feature_helper', __FILE__

When(/^client accepts JSON$/) do
  header 'Accept', 'application/json'
end

When(/^client follows redirection$/) do
  follow_redirect!
end



When(/^client requests GET (.*?)$/) do |url|
  get url
end

When(/^client requests POST (.*?) with form parameters: (.*?)$/) do |url, form_parameters|
  post url, params: eval(form_parameters)
end

When(/^client requests POST (.*?) with JSON parameter:$/) do |url, string|
  post url, parse(string).to_json, { 'CONTENT_TYPE' => 'application/json' }
end



Then(/^response status should be (\d+)$/) do |expected_status|
  expect(last_response.status).to be expected_status.to_i
end

Then(/^response body should be JSON:$/) do |string|
  expect(parse(last_response.body)).to eq(JSON.parse(string))
end

