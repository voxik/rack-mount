require 'test_helper'
require 'functional/route_set_test'

class LinearRouteSetTest < RouteSetTest
  def setup
    @app = LinearBasicSet
  end

  def test_worst_case
    assert_equal @app.length, @app.instance_variable_get('@recognition_graph').height
    assert_equal @app.length, @app.instance_variable_get('@generation_graph').height
  end

  def test_average_case
    assert_equal @app.length, @app.instance_variable_get('@recognition_graph').average_height.to_i
    assert_equal @app.length, @app.instance_variable_get('@generation_graph').average_height.to_i
  end
end
