require 'rubygems'
require 'rack/mount'
require 'fixtures'
require 'benchmark'

TIMES = 100_000.to_i
Set = DeeplyNestedSet

Benchmark.bmbm do |x|
  x.report('match 3 levels (hit)')  { TIMES.times { Set['a', 'a', 'a'] } }
  x.report('match 3 levels (miss)') { TIMES.times { Set['a', 'a', '!'] } }

  x.report('match 2 levels (hit)')  { TIMES.times { Set['a', 'a'] } }
  x.report('match 2 levels (miss)') { TIMES.times { Set['a', '!'] } }

  x.report('match 1 level (hit)')  { TIMES.times { Set['a'] } }
  x.report('match 1 level (miss)') { TIMES.times { Set['!'] } }
end
