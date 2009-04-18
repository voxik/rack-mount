require 'rubygems'
require 'rack'
require 'rack/mount'
require 'lib/performance_helper'

TIMES = 10_000.to_i
Env = EnvGenerator.env_for(TIMES, '/foo')

Benchmark.bmbm do |x|
  x.report('unoptimized') { TIMES.times { |n| BasicSet.call(Env[n]) } }
  x.report('optimized')   { TIMES.times { |n| OptimizedBasicSet.call(Env[n]) } }
end
