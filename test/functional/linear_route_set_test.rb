require 'test_helper'
require 'functional/route_set_test'

class LinearRouteSetTest < RouteSetTest
  def setup
    @app = LinearBasicSet
  end

  def test_worst_case
    assert_equal @app.length, @app.height
  end
end
