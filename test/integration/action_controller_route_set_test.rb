require 'test_helper'
require 'integration/route_set_tests'

class ActionControllerRouteSetTest < Test::Unit::TestCase
  include RouteSetTests

  def assert_loaded!
    if defined? ActionController::Routing::RouteSet::Dispatcher
      flunk "ActionController tests are running on monkey patched RouteSet"
    end
  end
end
