require 'performance_helper'

Map = lambda do |r|
  ('a'..'zz').each do |path|
    r.map "/#{path}", :to => EchoApp
  end
end

require 'rack/mount'
require 'rack/mount/mappers/simple'
Mount = Rack::Mount::RouteSet.new(:optimize => true).prepare(&Map)

require 'rack/router'
Router = Rack::Router.new(&Map)

TIMES = 10_000.to_i
FirstEnv = EnvGenerator.env_for(TIMES, '/a')
MidEnv = EnvGenerator.env_for(TIMES, '/mn')
LastEnv = EnvGenerator.env_for(TIMES, '/zz')

Benchmark.bmbm do |x|
  x.report('rack-mount (first)')  { TIMES.times { |n| Mount.call(FirstEnv[n]) } }
  x.report('rack-router (first)') { TIMES.times { |n| Router.call(FirstEnv[n]) } }
  x.report('rack-mount (mid)')    { TIMES.times { |n| Mount.call(MidEnv[n]) } }
  x.report('rack-router (mid)')   { TIMES.times { |n| Router.call(MidEnv[n]) } }
  x.report('rack-mount (last)')   { TIMES.times { |n| Mount.call(LastEnv[n]) } }
  x.report('rack-router (last)')  { TIMES.times { |n| Router.call(LastEnv[n]) } }
end
