require 'rack/test'
require 'json_spec/cucumber'

require 'active_support/inflector'



require File.expand_path('../../backend', __FILE__)

OmniAuth.config.test_mode = true

include Rack::Test::Methods
