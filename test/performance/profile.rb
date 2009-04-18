require 'rubygems'
require 'rack'

require 'rack/mount'
require 'lib/performance_helper'

Env = EnvGenerator.env_for(2, '/foo')

Routes = OptimizedBasicSet
Routes.call(Env[0])

profile_all(:profile) do
  Routes.call(Env[1])
end
