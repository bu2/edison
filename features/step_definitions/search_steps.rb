require File.expand_path '../../feature_helper', __FILE__

When(/^client requests POST (.*?) with JSON: (.*?)$/) do |url, string|
  post url, parse(string).to_json, { 'CONTENT_TYPE' => 'application/json' }
end
