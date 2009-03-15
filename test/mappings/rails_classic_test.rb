require 'test_helper'
require 'rack/mount/mappers/rails_classic'

class RailsClassicApiTest < Test::Unit::TestCase
  include TestHelper
  include BasicRecognitionTests

  Routes = Rack::Mount::RouteSet.new
  Routes.draw do |map|
    map.namespace :admin do |admin|
      admin.resources :accounts
    end

    map.resources :people

    map.connect '', :controller => 'homepage'

    map.geocode 'geocode/:postalcode', :controller => 'geocode',
                 :action => 'show', :postalcode => /\d{5}(-\d{4})?/
    map.geocode2 'geocode2/:postalcode', :controller => 'geocode',
                 :action => 'show', :requirements => { :postalcode => /\d{5}(-\d{4})?/ }

    map.with_options :controller => "sessions" do |sessions|
      sessions.login   "login",  :action => "new",     :conditions => { :method => :get }
      sessions.connect "login",  :action => "create",  :conditions => { :method => :post }
      sessions.logout  "logout", :action => "destroy", :conditions => { :method => :delete }
    end

    map.with_options :controller => "global" do |global|
      global.connect         "global/:action"
      global.export_request  "global/export",      :action => "export"
      global.hide_notice     "global/hide_notice", :action => "hide_notice"
      global.export_download "/export/:id/:file",  :action => "export", :file => /.*/
    end

    map.connect "foo", :controller => "foo", :action => "index"
    map.connect "foo/bar", :controller => "foo_bar", :action => "index"
    map.connect "/baz", :controller => "baz", :action => "index"

    map.connect "files/*files", :controller => "files", :action => "index"

    map.connect ':controller/:action/:id'
    map.connect ':controller/:action/:id.:format'
  end

  def setup
    @app = Routes
  end

  def test_namespace
    get "/admin/accounts"
    assert env
    assert_equal("GET", env["REQUEST_METHOD"])
    assert_equal({ :controller => "admin/accounts", :action => "index" }, env["rack.routing_args"])

    put "/admin/accounts/1"
    assert env
    assert_equal("PUT", env["REQUEST_METHOD"])
    assert_equal({ :controller => "admin/accounts", :action => "update", :id => "1" }, env["rack.routing_args"])

    get "/admin"
    assert_nil env
  end

  def test_url_for
    assert_equal "/login", @app.url_for(:login)
    assert_equal "/logout", @app.url_for(:logout)
    assert_equal "/geocode/60622", @app.url_for(:geocode, :postalcode => "60622")
  end

  def test_worst_case
    # Make sure we aren't making the tree less efficient. Its okay if
    # this number gets smaller. However it may increase if the more
    # routes are added to the test fixture.
    assert_equal 39, Routes.height
    assert_equal ":controller/:action/:id.:format", Routes.deepest_node.path
  end
end
