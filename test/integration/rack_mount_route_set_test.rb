unless RUBY_VERSION == '1.9.2'
  require 'abstract_unit'
  require 'integration/route_set_tests'

  class RackMountRouteSetTest < Test::Unit::TestCase
    include RouteSetTests

    def setup
      require File.join(File.dirname(__FILE__), '..', '..', 'rails', 'init')
      super
    end

    def assert_loaded!
      unless defined? ActionController::Routing::RouteSet::Dispatcher
        flunk "Rack::Mount tests are running without the proper monkey patch"
      end
    end
  end
end
