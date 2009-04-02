require 'test_helper'
require 'rack/mount/mappers/rails_draft'

class RailsDraftApiTest < Test::Unit::TestCase
  include TestHelper
  include BasicRecognitionTests

  class CatchRoutingErrors
    def initialize(app)
      @app = app
    end

    def call(env)
      @app.call(env)
    rescue Rack::Mount::Mappers::RailsDraft::RoutingError
      Rack::Mount::Const::NOT_FOUND_RESPONSE
    end

    def method_missing(*args, &block)
      @app.send(*args, &block)
    end
  end

  Routes = Rack::Mount::RouteSet.new
  Routes.new_draw do |map|
    resources :people

    match '', :to => 'homepage'

    match 'geocode/:postalcode',  :to => 'geocode#show', :as => :geocode, :constraints => { :postalcode => /\d{5}(-\d{4})?/ }
    match 'geocode2/:postalcode', :to => 'geocode#show', :as => :geocode, :constraints => { :postalcode => /\d{5}(-\d{4})?/ }

    controller :sessions do
      match 'logout', :via => :delete, :to => :destroy, :as => :logout

      match 'login' do
        get  :new, :as => :login
        post :create
      end
    end

    controller :global do
      match 'global/:action'
      match 'global/export',      :to => :export, :as => :export_request
      match 'global/hide_notice', :to => :hide_notice, :as => :hide_notice
      match '/export/:id/:file',  :to => :export, :as => :export_download, :constraints => { :file => /.*/ }
    end

    match 'people/:id/update', :to => 'people#update', :as => :update_person
    match '/projects/:project_id/people/:id/update', :to => 'people#update', :as => :update_project_person

    match 'articles/:year/:month/:day/:title', :to => "articles#show", :as => :article

    namespace :account do
      resources :subscription, :credit, :credit_card
    end

    controller :articles do
      match 'articles2' do
        match ':title', :title => /[a-z]+/, :as => :with_title do
          match ':id', :to => :with_id
        end
      end
    end

    match ':access_token', :constraints => { :access_token => /\w{5,5}/ } do
      resources :rooms
    end

    match 'foo', :to => 'foo#index'
    match 'foo/bar', :to => 'foo_bar#index'
    match '/baz', :to => 'baz#index'

    match '/optional/index(.:format)', :to => 'optional#index'

    if RUBY_VERSION >= '1.9'
      match eval("%r{^/regexp/foos?/(?<action>bar|baz)/(?<id>[a-z0-9]+)}"), :to => "foo"
    else
      match %r{^/regexp/foos?/(?:<action>bar|baz)/(?:<id>[a-z0-9]+)}, :to => "foo"
    end

    match 'files/*files', :to => 'files#index'

    match 'params_with_defaults(/:controller)', :to => "foo"
    match 'default/:controller/:action/:id'
    match 'default/:controller/:action/:id.:format'
  end

  def test_misc_routes
    get "/people/1/update"
    assert_success
    assert_equal({ :controller => "people", :action => "update", :id => "1"}, routing_args)

    get "/projects/1/people/2/update"
    assert_success
    assert_equal({ :project_id => "1", :controller => "people", :id => "2", :action => "update" }, routing_args)

    get "/articles/2009/1/19/birthday"
    assert_success
    assert_equal({ :controller => "articles", :action => "show", :year => "2009", :month => "1", :day => "19", :title => "birthday" }, routing_args)
  end

  def test_nested_route
    get "/articles2/hello/1"
    assert_success
    assert_equal({ :controller => "articles", :action => "with_id", :title => "hello", :id => "1" }, routing_args)
  end

  def test_nested_resource
    get "/12345/rooms"
    assert_success
    assert_equal({ :controller => "rooms", :action => "index", :access_token => "12345" }, routing_args)

    get "/12345/rooms/1"
    assert_success
    assert_equal({ :controller => "rooms", :action => "show", :access_token => "12345", :id => "1" }, routing_args)
  end

  def setup
    @app = CatchRoutingErrors.new(Routes)
  end
end
