require 'helper'

TIMES = 10_000.to_i
Env = EnvGenerator.env_for(TIMES, '/account/credit_card/1')

Benchmark.bmbm do |x|
  x.report('unoptimized') { TIMES.times { |n| BasicSet.call(Env[n]) } }
  x.report('optimized')   { TIMES.times { |n| OptimizedBasicSet.call(Env[n]) } }
end

#                   user     system      total        real
# unoptimized   0.920000   0.000000   0.920000 (  0.924905)
# optimized     0.810000   0.000000   0.810000 (  0.809464)

puts

env = Rack::MockRequest.env_for('/account/credit_card/1')
profile_memory_usage { BasicSet.call(env) }

# 4.61 KB        124 alloc         -3 obj      1.4 ms  0 KB RSS


puts

env = Rack::MockRequest.env_for('/account/credit_card/1')
profile_memory_usage { OptimizedBasicSet.call(env) }

# 5.15 KB        289 alloc         -4 obj      1.0 ms  0 KB RSS
