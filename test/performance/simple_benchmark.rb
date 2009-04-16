require 'rubygems'
require 'rack/mount'
require 'rack/mount/mappers/rails_classic'

Response = [200, {Rack::Mount::Const::CONTENT_TYPE => 'text/plain'}, []]
EchoApp = lambda { |env| Response }

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

Env = Rack::MockRequest.env_for('/zz/1')
Routes = Rack::Mount::RouteSet.new.draw(&Map)

require 'benchmark'

TIMES = 10_000.to_i

Benchmark.bmbm do |x|
  x.report('hash bucket') { TIMES.times { Routes.call(Env.dup) } }
end
