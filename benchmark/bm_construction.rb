require 'helper'
require 'fixtures'

Benchmark.bmbm do |x|
  x.report { Rack::Mount::RouteSet.new(&BasicSetMap) }
end

#     user     system      total        real
# 0.290000   0.010000   0.300000 (  0.295858)

puts

profile_memory_usage do
  Rack::Mount::RouteSet.new(&BasicSetMap)
end

# 27181.19 KB     805099 alloc         -3 obj    300.0 ms  0 KB RSS
