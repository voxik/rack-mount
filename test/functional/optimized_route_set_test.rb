require 'test_helper'
require 'functional/route_set_test'

class OptimizedRouteSetTest < RouteSetTest
  def setup
    @app = OptimizedBasicSet
    assert set_included_modules.include?(Rack::Mount::Recognition::CodeGeneration)
  end
end
