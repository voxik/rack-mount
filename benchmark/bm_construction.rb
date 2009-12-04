require 'helper'
require 'fixtures'

Benchmark.bmbm do |x|
  x.report { Rack::Mount::RouteSet.new(&BasicSetMap) }
end

#     user     system      total        real
# 0.170000   0.000000   0.170000 (  0.178076)

puts

profile_memory_usage do
  Rack::Mount::RouteSet.new(&BasicSetMap)
end

# 17248.56 KB     520719 alloc         -3 obj    200.5 ms  0 KB RSS
