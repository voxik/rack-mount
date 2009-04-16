require 'rubygems'
require 'ruby-prof'

require 'rack/mount'
require 'lib/performance_helper'
require 'fixtures'

Env = Rack::MockRequest.env_for('/foo')
Response = [200, {Rack::Mount::Const::CONTENT_TYPE => 'text/plain'}, []]
EchoApp = lambda { |env| Response }

routes = BasicSet
routes.call(Env.dup)

profile_all(:profile) do
  routes.call(Env.dup)
end
