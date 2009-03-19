require 'test_helper'
require 'rack/mount/mappers/rails_draft'

class RailsDraftApiTest < Test::Unit::TestCase
  include TestHelper
  include BasicRecognitionTests

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


    namespace :account do
      resource :subscription, :credit, :credit_card
    end

    controller :articles do
      match 'articles' do
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

    match 'files/*files', :to => 'files#index'

    match ':controller/:action/:id'
    match ':controller/:action/:id.:format'
  end

  def test_namespaced_resources
    get "/account/subscription"
    assert env
    assert_equal("GET", env["REQUEST_METHOD"])
    assert_equal({ :controller => "subscription", :action => "index" }, env["rack.routing_args"])

    get "/account/credit"
    assert env
    assert_equal("GET", env["REQUEST_METHOD"])
    assert_equal({ :controller => "credit", :action => "index" }, env["rack.routing_args"])
  end

  def test_nested_route
    get "/articles/hello/1"
    assert env
    assert_equal("GET", env["REQUEST_METHOD"])
    assert_equal({ :controller => "articles", :action => "with_id", :title => "hello", :id => "1" }, env["rack.routing_args"])
  end

  def test_nested_resource
    get "/12345/rooms"
    assert env
    assert_equal("GET", env["REQUEST_METHOD"])
    assert_equal({ :controller => "rooms", :action => "index", :access_token => "12345" }, env["rack.routing_args"])

    get "/12345/rooms/1"
    assert env
    assert_equal("GET", env["REQUEST_METHOD"])
    assert_equal({ :controller => "rooms", :action => "show", :access_token => "12345", :id => "1" }, env["rack.routing_args"])
  end

  def setup
    @app = Routes
  end
end
