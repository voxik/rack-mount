require 'test_helper'

class RawApiTest < Test::Unit::TestCase
  include TestHelper
  include BasicRecognitionTests

  Routes = Rack::Mount::RouteSet.new
  Routes.add_route(EchoApp, :path => "/people", :method => "get", :defaults => { :controller => "people", :action => "index" })
  Routes.add_route(EchoApp, :path => "/people", :method => "post", :defaults => { :controller => "people", :action => "create" })
  Routes.add_route(EchoApp, :path => "/people/new", :method => "get", :defaults => { :controller => "people", :action => "new" })
  Routes.add_route(EchoApp, :path => "/people/:id/edit", :method => "get", :defaults => { :controller => "people", :action => "edit" })
  Routes.add_route(EchoApp, :path => "/people/:id", :method => "get", :defaults => { :controller => "people", :action => "show" })
  Routes.add_route(EchoApp, :path => "/people/:id", :method => "put", :defaults => { :controller => "people", :action => "update" })
  Routes.add_route(EchoApp, :path => "/people/:id", :method => "delete", :defaults => { :controller => "people", :action => "destroy" })

  Routes.add_route(EchoApp, :path => "/", :defaults => { :controller => "homepage" })

  Routes.add_route(EchoApp, :path => "/geocode/:postalcode", :defaults => { :controller => "geocode", :action => "show" }, :requirements => { :postalcode => /\d{5}(-\d{4})?/ })
  Routes.add_route(EchoApp, :path => "/geocode2/:postalcode", :defaults => { :controller => "geocode", :action => "show" }, :requirements => { :postalcode => /\d{5}(-\d{4})?/ })

  Routes.add_route(EchoApp, :path => "/login", :method => "get", :defaults => { :controller => "sessions", :action => "new" })
  Routes.add_route(EchoApp, :path => "/login", :method => "post", :defaults => { :controller => "sessions", :action => "create" })
  Routes.add_route(EchoApp, :path => "/logout", :method => "delete", :defaults => { :controller => "sessions", :action => "destroy" })

  Routes.add_route(EchoApp, :path => "/global/:action", :defaults => { :controller => "global" })
  Routes.add_route(EchoApp, :path => "/global/export", :defaults => { :controller => "global", :action => "export" })
  Routes.add_route(EchoApp, :path => "/global/hide_notice", :defaults => { :controller => "global", :action => "hide_notice" })
  Routes.add_route(EchoApp, :path => "/export/:id/:file", :defaults => { :controller => "global", :action => "export" }, :requirements => { :file => /.*/ })

  Routes.add_route(EchoApp, :path => "foo", :defaults => { :controller => "foo", :action => "index" })
  Routes.add_route(EchoApp, :path => "foo/bar", :defaults => { :controller => "foo_bar", :action => "index" })
  Routes.add_route(EchoApp, :path => "/baz", :defaults => { :controller => "baz", :action => "index" })

  Routes.add_route(EchoApp, :path => "files/*files", :defaults => { :controller => "files", :action => "index" })

  Routes.add_route(EchoApp, :path => ":controller/:action/:id")
  Routes.add_route(EchoApp, :path => ":controller/:action/:id.:format")

  Routes.freeze

  def setup
    @app = Routes
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
end
