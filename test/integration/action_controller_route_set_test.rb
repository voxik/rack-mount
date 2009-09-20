unless RUBY_VERSION == '1.9.2'
  require 'abstract_unit'
  require 'integration/route_set_tests'

  class ActionControllerRouteSetTest < Test::Unit::TestCase
    include RouteSetTests

    def assert_loaded!
      if defined? ActionController::Routing::RouteSet::Dispatcher
        flunk "ActionController tests are running on monkey patched RouteSet"
      end
    end
  end
end
