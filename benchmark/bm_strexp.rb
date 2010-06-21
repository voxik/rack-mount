require 'helper'
require 'fixtures'

Strexp = Rack::Mount::Strexp

TIMES = 10_000.to_i

Benchmark.bmbm do |x|
  x.report('foo')              { TIMES.times { Strexp.compile('foo') } }
  x.report('foo/:bar')         { TIMES.times { Strexp.compile('foo/:bar') } }
  x.report('foo(.:extension)') { TIMES.times { Strexp.compile('foo(.:extension)') } }
  x.report('foo/*rest')        { TIMES.times { Strexp.compile('foo/*rest') } }

  x.report('a/:a(/b/:b(/c/:c(.:d)))') {
    TIMES.times { Strexp.compile('a/:a(/b/:b(/c/:c(.:d)))') }
  }
end

#                               user     system      total        real
# foo                       0.630000   0.020000   0.650000 (  0.646283)
# foo/:bar                  0.930000   0.030000   0.960000 (  0.963128)
# foo(.:extension)          1.150000   0.030000   1.180000 (  1.183852)
# foo/*rest                 0.910000   0.030000   0.940000 (  0.943856)
# a/:a(/b/:b(/c/:c(.:d)))   2.630000   0.070000   2.700000 (  2.709761)
