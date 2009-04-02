require 'test_helper'

class RouteSetTest < Test::Unit::TestCase
  include TestHelper
  include BasicRecognitionTests
  include BasicGenerationTests

  def setup
    @app = BasicSet
  end

  if RUBY_VERSION >= '1.9'
    def test_named_regexp_groups
      get "/ruby19/foo/1"
      assert_success
      assert_equal({ :controller => "ruby19", :action => "foo", :id => "1" }, routing_args)
    end

    def test_optional_segments_with_period
      get "/ruby19/index"
      assert_success
      assert_equal({ :controller => "ruby19", :action => "index" }, routing_args)

      get "/ruby19/index.xml"
      assert_success
      assert_equal({ :controller => "ruby19", :action => "index", :format => "xml" }, routing_args)
    end

    def test_optional_segments_with_slash
      get "/ruby19/foo"
      assert_success
      assert_equal({ :controller => "ruby19", :action => "foo" }, routing_args)

      get "/ruby19/foo/123"
      assert_success
      assert_equal({ :controller => "ruby19", :action => "foo", :id => "123" }, routing_args)
    end
  end

  def test_ensure_routeset_needs_to_be_frozen
    set = Rack::Mount::RouteSet.new
    assert_raise(RuntimeError) { set.call({}) }

    set.freeze
    assert_nothing_raised(RuntimeError) { set.call({}) }
  end

  def test_ensure_each_route_requires_a_valid_rack_app
    set = Rack::Mount::RouteSet.new
    assert_raise(ArgumentError) { set.add_route({}) }
    assert_raise(ArgumentError) { set.add_route(:app => "invalid app") }
  end

  def test_worst_case
    # Make sure we aren't making the tree less efficient. Its okay if
    # this number gets smaller. However it may increase if the more
    # routes are added to the test fixture.
    assert_equal 14, @app.height
    assert_equal "/params_with_defaults(/:controller)", @app.deepest_node.path
  end
end

class OptimizedRouteSetTest < RouteSetTest
  def setup
    @app = OptimizedBasicSet
  end
end

class LinearBasicSetTest < RouteSetTest
  def setup
    @app = LinearBasicSet
  end

  def test_worst_case
    # Skip assertions
  end
end
