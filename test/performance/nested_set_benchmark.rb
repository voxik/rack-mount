require 'performance/test_helper'

class Rack::Mount::NestedSet
  include Rack::Mount::NestedSetExt
end

TIMES = 100_000.to_i
Set = DeeplyNestedSet

Benchmark.bmbm do |x|
  x.report('match 3 levels (hit) (ruby)')  { TIMES.times { Set['a', 'a', 'a'] } }
  x.report('match 3 levels (hit) (c)')  { TIMES.times { Set.cfetch('a', 'a', 'a') } }
  x.report('match 3 levels (miss) (ruby)') { TIMES.times { Set['a', 'a', '!'] } }
  x.report('match 3 levels (miss) (c)') { TIMES.times { Set.cfetch('a', 'a', '!') } }

  x.report('match 2 levels (hit) (ruby)')  { TIMES.times { Set['a', 'a'] } }
  x.report('match 2 levels (hit) (c)')  { TIMES.times { Set.cfetch('a', 'a') } }
  x.report('match 2 levels (miss) (ruby)') { TIMES.times { Set['a', '!'] } }
  x.report('match 2 levels (miss) (c)') { TIMES.times { Set.cfetch('a', '!') } }

  x.report('match 1 level (hit) (ruby)')  { TIMES.times { Set['a'] } }
  x.report('match 1 level (hit) (c)')  { TIMES.times { Set.cfetch('a') } }
  x.report('match 1 level (miss) (ruby)') { TIMES.times { Set['!'] } }
  x.report('match 1 level (miss) (c)') { TIMES.times { Set.cfetch('!') } }
end
