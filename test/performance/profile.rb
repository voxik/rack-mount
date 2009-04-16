require 'rubygems'
require 'rack'
require 'ruby-prof'

require 'rack/mount'
require 'lib/performance_helper'
require 'fixtures'

Env = EnvGenerator.env_for(2, '/foo')
EchoApp = lambda { |env| Rack::Mount::Const::OK_RESPONSE }

Routes = OptimizedBasicSet
Routes.call(Env[0])

profile_all(:profile) do
  Routes.call(Env[1])
end
