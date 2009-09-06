require 'performance/test_helper'

require 'rack/mount'
Mount = Rack::Mount::RouteSet.new do |map|
  ('a'..'zz').each do |path|
    map.add_route(EchoApp, :path_info => "/#{path}")
  end
end

require 'usher'
Ush = Usher::Interface.for(:rack) do
  ('a'..'zz').each do |path|
    add("/#{path}").to(EchoApp)
  end
end

TIMES = 10_000.to_i

MountFirstEnv = EnvGenerator.env_for(TIMES, '/a')
UshFirstEnv = EnvGenerator.env_for(TIMES, '/a')

MountMidEnv = EnvGenerator.env_for(TIMES, '/mn')
UshMidEnv = EnvGenerator.env_for(TIMES, '/mn')

MountLastEnv = EnvGenerator.env_for(TIMES, '/zz')
UshLastEnv = EnvGenerator.env_for(TIMES, '/zz')

Benchmark.bmbm do |x|
  x.report('rack-mount (first)')  { TIMES.times { |n| Mount.call(MountFirstEnv[n]) } }
  x.report('usher (first)') { TIMES.times { |n| Ush.call(UshFirstEnv[n]) } }
  x.report('rack-mount (mid)')    { TIMES.times { |n| Mount.call(MountMidEnv[n]) } }
  x.report('usher (mid)')   { TIMES.times { |n| Ush.call(UshMidEnv[n]) } }
  x.report('rack-mount (last)')   { TIMES.times { |n| Mount.call(MountLastEnv[n]) } }
  x.report('usher (last)')  { TIMES.times { |n| Ush.call(UshLastEnv[n]) } }
end

#                          user     system      total        real
# rack-mount (first)   0.310000   0.000000   0.310000 (  0.315686)
# usher (first)        1.760000   0.010000   1.770000 (  1.761123)
# rack-mount (mid)     0.310000   0.000000   0.310000 (  0.317276)
# usher (mid)          1.880000   0.010000   1.890000 (  1.891970)
# rack-mount (last)    0.320000   0.000000   0.320000 (  0.319082)
# usher (last)         1.860000   0.000000   1.860000 (  1.871472)
