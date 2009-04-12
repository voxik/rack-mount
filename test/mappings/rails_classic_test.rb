require 'test_helper'
require 'rack/mount/mappers/rails_classic'

class RailsClassicApiTest < Test::Unit::TestCase
  include TestHelper
  include BasicRecognitionTests
  include BasicGenerationTests

  class CatchRoutingErrors
    def initialize(app)
      @app = app
    end

    def call(env)
      @app.call(env)
    rescue Rack::Mount::Mappers::RailsClassic::RoutingError
      Rack::Mount::Const::NOT_FOUND_RESPONSE
    end

    def method_missing(*args, &block)
      @app.send(*args, &block)
    end
  end

  Routes = Rack::Mount::RouteSet.new
  Routes.draw do |map|
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

    map.namespace :account do |account|
      account.resources :subscription, :credit, :credit_card
    end

    map.connect "foo", :controller => "foo", :action => "index"
    map.connect "foo/bar", :controller => "foo_bar", :action => "index"
    map.connect "/baz", :controller => "baz", :action => "index"

    map.connect "/optional/index.:format", :controller => "optional", :action => "index"

    if Rack::Mount::Const::SUPPORTS_NAMED_CAPTURES
      map.connect eval("%r{^/regexp/foos?/(?<action>bar|baz)/(?<id>[a-z0-9]+)}"), :controller => "foo"
    else
      map.connect %r{^/regexp/foos?/(?:<action>bar|baz)/(?:<id>[a-z0-9]+)}, :controller => "foo"
    end

    map.connect "files/*files", :controller => "files", :action => "index"

    map.connect 'params_with_defaults/:controller', :controller => "foo"
    map.connect 'default/:controller/:action/:id.:format'
  end

  def setup
    @app = CatchRoutingErrors.new(Routes)
  end
end
