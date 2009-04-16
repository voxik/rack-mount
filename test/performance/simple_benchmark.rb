require 'rubygems'
require 'rack/mount'
require 'rack/mount/mappers/rails_classic'
require 'fixtures'

EchoApp = lambda { |env| Rack::Mount::Const::OK_RESPONSE }

def Object.const_missing(name)
  if name.to_s =~ /Controller$/
    EchoApp
  else
    super
  end
end

Map = lambda do |map|
  resources = ('a'..'zz')

  resources.each do |resource|
    map.resource resource.to_s
  end

  map.connect ':controller/:action/:id'
end

TIMES = 10_000.to_i
Routes = Rack::Mount::RouteSet.new.draw(&Map)
Env = EnvGenerator.env_for(TIMES, '/zz/1')

require 'benchmark'

Benchmark.bmbm do |x|
  x.report('hash bucket') { TIMES.times { |n| Routes.call(Env[n]) } }
end
