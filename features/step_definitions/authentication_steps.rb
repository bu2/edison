require File.expand_path '../../feature_helper', __FILE__

Given(/^client is not authenticated$/) do
end

Given(/^client is authenticated$/) do
  authenticate_as_bob
end

Given(/^client is authenticated as (.*?)$/) do |name|
  case name
    when 'Bob' then authenticate_as_bob
    when 'John' then authenticate_as_john
  end
end
