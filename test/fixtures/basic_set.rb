require 'lib/without_optimizations'

Rack::Mount::RouteSet.without_optimizations do
  BasicSet = Rack::Mount::RouteSet.new(&BasicSetMap)
end
