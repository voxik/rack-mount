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
FirstEnv = EnvGenerator.env_for(TIMES, '/a')
MidEnv = EnvGenerator.env_for(TIMES, '/mn')
LastEnv = EnvGenerator.env_for(TIMES, '/zz')

Benchmark.bmbm do |x|
  x.report('rack-mount (first)')  { TIMES.times { |n| Mount.call(FirstEnv[n]) } }
  x.report('usher (first)') { TIMES.times { |n| Ush.call(FirstEnv[n]) } }
  x.report('rack-mount (mid)')    { TIMES.times { |n| Mount.call(MidEnv[n]) } }
  x.report('usher (mid)')   { TIMES.times { |n| Ush.call(MidEnv[n]) } }
  x.report('rack-mount (last)')   { TIMES.times { |n| Mount.call(LastEnv[n]) } }
  x.report('usher (last)')  { TIMES.times { |n| Ush.call(LastEnv[n]) } }
end

#                          user     system      total        real
# rack-mount (first)   0.270000   0.000000   0.270000 (  0.279772)
# usher (first)        1.800000   0.010000   1.810000 (  1.812982)
# rack-mount (mid)     0.280000   0.000000   0.280000 (  0.280072)
# usher (mid)          1.780000   0.000000   1.780000 (  1.784955)
# rack-mount (last)    0.300000   0.000000   0.300000 (  0.308182)
# usher (last)         1.730000   0.000000   1.730000 (  1.738455)
