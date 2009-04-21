require 'test_helper'

class RouteSetTest < Test::Unit::TestCase
  include TestHelper
  include BasicRecognitionTests
  include BasicGenerationTests

  def setup
    @app = BasicSet
  end

  def test_path_prefix
    get '/prefix/foo/bar/1'
    assert_success
    assert_equal({ :controller => 'foo', :action => 'bar', :id => '1' }, routing_args)
  end

  def test_ensure_routeset_needs_to_be_frozen
    set = Rack::Mount::RouteSet.new
    assert_raise(RuntimeError) { set.call({}) }

    set.freeze
    assert_frozen(set)
    assert_nothing_raised(RuntimeError) { set.call({}) }
  end

  def test_ensure_each_route_requires_a_valid_rack_app
    set = Rack::Mount::RouteSet.new
    assert_nothing_raised(ArgumentError) { set.add_route(EchoApp, :path => '/foo') }
    assert_raise(ArgumentError) { set.add_route({}) }
    assert_raise(ArgumentError) { set.add_route('invalid app') }
  end

  def test_ensure_route_has_valid_conditions
    set = Rack::Mount::RouteSet.new
    assert_nothing_raised(ArgumentError) { set.add_route(EchoApp, :path => '/foo') }
    assert_raise(ArgumentError) { set.add_route(EchoApp, nil) }
    assert_raise(ArgumentError) { set.add_route(EchoApp, :foo => '/bar') }
  end

  def test_worst_case
    # Make sure we aren't making the tree less efficient. Its okay if
    # this number gets smaller. However it may increase if the more
    # routes are added to the test fixture.
    assert_equal 12, @app.height
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
