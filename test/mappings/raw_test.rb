require 'test_helper'

class RawApiTest < Test::Unit::TestCase
  include TestHelper
  include BasicRecognitionTests

  Routes = Rack::Mount::RouteSet.new
  Routes.add_route(:path => "/people", :method => "get", :defaults => { :controller => "people", :action => "index" }, :app => PeopleController)
  Routes.add_route(:path => "/people", :method => "post", :defaults => { :controller => "people", :action => "create" }, :app => PeopleController)
  Routes.add_route(:path => "/people/new", :method => "get", :defaults => { :controller => "people", :action => "new" }, :app => PeopleController)
  Routes.add_route(:path => "/people/:id/edit", :method => "get", :defaults => { :controller => "people", :action => "edit" }, :app => PeopleController)
  Routes.add_route(:path => "/people/:id", :method => "get", :defaults => { :controller => "people", :action => "show" }, :requirements => { :id => /\d+/ }, :app => PeopleController)
  Routes.add_route(:path => "/people/:id", :method => "put", :defaults => { :controller => "people", :action => "update" }, :requirements => { :id => /\d+/ }, :app => PeopleController)
  Routes.add_route(:path => "/people/:id", :method => "delete", :defaults => { :controller => "people", :action => "destroy" }, :requirements => { :id => /\d+/ }, :app => PeopleController)

  Routes.add_route(:path => "/", :defaults => { :controller => "homepage" }, :app => HomepageController)

  Routes.add_route(:path => "/geocode/:postalcode", :defaults => { :controller => "geocode", :action => "show" }, :requirements => { :postalcode => /\d{5}(-\d{4})?/ }, :app => GeocodeController)
  Routes.add_route(:path => "/geocode2/:postalcode", :defaults => { :controller => "geocode", :action => "show" }, :requirements => { :postalcode => /\d{5}(-\d{4})?/ }, :app => GeocodeController)

  Routes.add_route(:path => "/login", :method => "get", :defaults => { :controller => "sessions", :action => "new" }, :app => SessionsController)
  Routes.add_route(:path => "/login", :method => "post", :defaults => { :controller => "sessions", :action => "create" }, :app => SessionsController)
  Routes.add_route(:path => "/logout", :method => "delete", :defaults => { :controller => "sessions", :action => "destroy" }, :app => SessionsController)

  Routes.add_route(:path => "/global/:action", :defaults => { :controller => "global" }, :app => GlobalController)
  Routes.add_route(:path => "/global/export", :defaults => { :controller => "global", :action => "export" }, :app => GlobalController)
  Routes.add_route(:path => "/global/hide_notice", :defaults => { :controller => "global", :action => "hide_notice" }, :app => GlobalController)
  Routes.add_route(:path => "/export/:id/:file", :defaults => { :controller => "global", :action => "export" }, :requirements => { :file => /.*/ }, :app => GlobalController)

  Routes.add_route(:path => "foo", :defaults => { :controller => "foo", :action => "index" }, :app => FooController)
  Routes.add_route(:path => "foo/bar", :defaults => { :controller => "foo_bar", :action => "index" }, :app => FooBarController)
  Routes.add_route(:path => "/baz", :defaults => { :controller => "baz", :action => "index" }, :app => BazController)

  Routes.add_route(:path => "files/*files", :defaults => { :controller => "files", :action => "index" }, :app => FilesController)

  Routes.add_route(:path => ":controller/:action/:id", :app => DefaultController)
  Routes.add_route(:path => ":controller/:action/:id.:format", :app => DefaultController)

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
end
