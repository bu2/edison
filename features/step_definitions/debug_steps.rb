require File.expand_path '../../feature_helper', __FILE__

Then(/^debug$/) do
  require 'pry'
  binding.pry
end
