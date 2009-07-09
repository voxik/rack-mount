require 'test_helper'
require 'integration/route_set_tests'

module ActionController
  module Routing
    class RouteSet
      # TODO: Deprecate sorted behavior in Rails core
      def routes_for_controller_and_action_and_keys(controller, action, keys)
        routes.select { |route| route.matches_controller_and_action?(controller, action) }
      end
    end
  end
end

class ActionControllerRouteSetTest < Test::Unit::TestCase
  include RouteSetTests

  def assert_loaded!
    if defined? ActionController::Routing::RouteSet::Dispatcher
      flunk "ActionController tests are running on monkey patched RouteSet"
    end
  end
end
