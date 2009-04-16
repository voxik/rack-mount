require 'rubygems'
require 'ruby-prof'

require 'rack/mount'
require 'lib/performance_helper'
require 'fixtures'

Env = {
  'REQUEST_METHOD' => 'GET',
  'PATH_INFO' => '/foo'
}.freeze

Response = [200, {'Content-Type' => 'text/plain'}, []]
EchoApp = lambda { |env| Response }

routes = BasicSet
routes.call(Env.dup)

profile_all(:profile) do
  routes.call(Env.dup)
end
