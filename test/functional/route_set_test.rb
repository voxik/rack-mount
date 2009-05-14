require 'test_helper'

class RouteSetTest < Test::Unit::TestCase
  include RequestDSL
  include BasicRecognitionTests
  include BasicGenerationTests

  def setup
    @app = BasicSet
    assert !set_included_modules.include?(Rack::Mount::Recognition::Optimizations)
  end

  def test_slashes
    get '/slashes/trailing/'
    assert_success
    assert_equal({ :controller => 'slash', :action => 'trailing' }, routing_args)

    get '/slashes/trailing'
    assert_success
    assert_equal({ :controller => 'slash', :action => 'trailing' }, routing_args)

    get '/slashes/repeated'
    assert_success
    assert_equal({ :controller => 'slash', :action => 'repeated' }, routing_args)
  end

  def test_method_regexp
    get '/method'
    assert_success
    assert_equal({ :controller => 'method', :action => 'index' }, routing_args)

    post '/method'
    assert_success
    assert_equal({ :controller => 'method', :action => 'index' }, routing_args)

    # put '/method'
    # assert_not_found

    # delete '/method'
    # assert_not_found
  end

  def test_schema_condition
    get '/ssl', 'rack.url_scheme' => 'http'
    assert_success
    assert_equal({ :controller => 'ssl', :action => 'nonssl' }, routing_args)

    get '/ssl', 'rack.url_scheme' => 'https'
    assert_success
    assert_equal({ :controller => 'ssl', :action => 'ssl' }, routing_args)
  end

  def test_host_condition
    get '/host', 'HTTP_HOST' => '37s.backpackit.com'
    assert_success
    assert_equal({ :controller => 'account', :account => '37s' }, routing_args)

    get '/host', 'HTTP_HOST' => 'josh.backpackit.com'
    assert_success
    assert_equal({ :controller => 'account', :account => 'josh' }, routing_args)

    get '/host', 'HTTP_HOST' => 'nil.backpackit.com'
    assert_not_found
  end

  def test_path_prefix
    get '/prefix/foo/bar/1'
    assert_success
    assert_equal({ :controller => 'foo', :action => 'bar', :id => '1' }, routing_args)
  end

  def test_uses_default_parameters_when_non_are_passed
    assert_equal '/feed/atom', @app.url_for(:feed, :kind => 'atom')
    assert_equal '/feed/rss', @app.url_for(:feed)
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
    assert_equal 3, @app.height
  end

  private
    def set_included_modules
      class << @app; included_modules; end
    end
end

class OptimizedRouteSetTest < RouteSetTest
  def setup
    @app = OptimizedBasicSet
    assert set_included_modules.include?(Rack::Mount::Recognition::Optimizations)
  end
end
