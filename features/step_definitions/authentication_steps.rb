require File.expand_path '../../feature_helper', __FILE__

Given(/^client is not authenticated$/) do
end

Given(/^client is authenticated$/) do
  authenticate_as_bob
end
