require 'rubygems'
require 'ruby-prof'

require 'rack/mount'
require 'lib/performance_helper'
require 'fixtures'

Env = {
  Rack::Mount::Const::REQUEST_METHOD => 'GET',
  Rack::Mount::Const::PATH_INFO => '/foo'
}.freeze

Response = [200, {Rack::Mount::Const::CONTENT_TYPE => 'text/plain'}, []]
EchoApp = lambda { |env| Response }

routes = BasicSet
routes.call(Env.dup)

profile_all(:profile) do
  routes.call(Env.dup)
end
