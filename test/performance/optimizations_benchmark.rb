require 'rubygems'
require 'rack'
require 'rack/mount'
require 'fixtures'

TIMES = 10_000.to_i
EchoApp = lambda { |env| Rack::Mount::Const::OK_RESPONSE }
Env = EnvGenerator.env_for(TIMES, '/foo')

require 'benchmark'

Benchmark.bmbm do |x|
  x.report('unoptimized') { TIMES.times { |n| BasicSet.call(Env[n]) } }
  x.report('optimized')   { TIMES.times { |n| OptimizedBasicSet.call(Env[n]) } }
end
