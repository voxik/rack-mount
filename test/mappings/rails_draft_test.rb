require 'test_helper'

class RailsDraftApiTest < Test::Unit::TestCase
  include TestHelper
  include BasicRecognitionTests

  Routes = Rack::Mount::RouteSet.new
  Routes.new_draw do |map|
    resources :people

    match '', :to => 'homepage'

    match 'geocode/:postalcode',  :to => 'geocode#show', :as => :geocode, :constraints => { :postalcode => /\d{5}(-\d{4})?/ }
    match 'geocode2/:postalcode', :to => 'geocode#show', :as => :geocode, :constraints => { :postalcode => /\d{5}(-\d{4})?/ }

    controller :global do
      match 'global/:action'
      match 'global/export',      :to => :export, :as => :export_request
      match 'global/hide_notice', :to => :hide_notice, :as => :hide_notice
      match '/export/:id/:file',  :to => :export, :as => :export_download, :constraints => { :file => /.*/ }
    end

    match 'foo', :to => 'foo#index'
    match 'foo/bar', :to => 'foo_bar#index'
    match '/baz', :to => 'baz#index'

    match 'files/*files', :to => 'files#index'

    match ':controller/:action/:id'
    match ':controller/:action/:id.:format'
  end

  def setup
    @app = Routes
  end
end
