require 'rubygems'

require 'rack/mount'
require 'rack/mount/mappers/rails_classic'
require 'fixtures'

Response = [200, {Rack::Mount::Const::CONTENT_TYPE => 'text/plain'}, []]
EchoApp = lambda { |env| Response }
Env = Rack::MockRequest.env_for('/foo')

require 'benchmark'

TIMES = 10_000.to_i

Benchmark.bmbm do |x|
  x.report('unoptimized') { TIMES.times { BasicSet.call(Env.dup) } }
  x.report('optimized')   { TIMES.times { OptimizedBasicSet.call(Env.dup) } }
end
