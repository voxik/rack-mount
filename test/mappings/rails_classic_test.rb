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
    rescue ActionController::RoutingError
      Rack::Mount::Const::NOT_FOUND_RESPONSE
    end

    def method_missing(*args, &block)
      @app.send(*args, &block)
    end
  end

  ActionController::Routing::Routes.draw do |map|
    map.resources :people

    map.connect '', :controller => 'homepage'

    map.geocode 'geocode/:postalcode', :controller => 'geocode',
                 :action => 'show', :postalcode => /\d{5}(-\d{4})?/
    map.geocode2 'geocode2/:postalcode', :controller => 'geocode',
                 :action => 'show', :requirements => { :postalcode => /\d{5}(-\d{4})?/ }

    map.with_options :controller => 'sessions' do |sessions|
      sessions.login   'login',  :action => 'new',     :conditions => { :method => :get }
      sessions.connect 'login',  :action => 'create',  :conditions => { :method => :post }
      sessions.logout  'logout', :action => 'destroy', :conditions => { :method => :delete }
    end

    map.with_options :controller => 'global' do |global|
      global.connect         'global/:action'
      global.export_request  'global/export',      :action => 'export'
      global.hide_notice     'global/hide_notice', :action => 'hide_notice'
      global.export_download '/export/:id/:file',  :action => 'export', :file => /.*/
    end

    map.namespace :account do |account|
      account.resources :subscription, :credit, :credit_card
    end

    map.connect 'foo', :controller => 'foo', :action => 'index'
    map.connect 'foo/bar', :controller => 'foo_bar', :action => 'index'
    map.connect '/baz', :controller => 'baz', :action => 'index'

    map.connect '/optional/index.:format', :controller => 'optional', :action => 'index'

    if Rack::Mount::Const::SUPPORTS_NAMED_CAPTURES
      map.connect eval('%r{^/regexp/foos?/(?<action>bar|baz)/(?<id>[a-z0-9]+)}'), :controller => 'foo'
      map.complex_regexp eval('%r{^/regexp/bar/(?<action>[a-z]+)/(?<id>[0-9]+)$}'), :controller => 'foo'
    else
      map.connect %r{^/regexp/foos?/(?:<action>bar|baz)/(?:<id>[a-z0-9]+)}, :controller => 'foo'
      map.complex_regexp %r{^/regexp/bar/(?:<action>[a-z]+)/(?:<id>[0-9]+)$}, :controller => 'foo'
    end
    map.complex_regexp_fail %r{^/regexp/baz/[a-z]+/[0-9]+$}, :controller => 'foo'

    map.connect 'files/*files', :controller => 'files', :action => 'index'

    map.connect 'params_with_defaults/:controller', :controller => 'foo'
    map.connect 'default/:controller/:action/:id.:format'
    map.connect nil, :controller => 'global', :action => 'destroy', :conditions => { :method => :delete }
  end

  def setup
    @app = CatchRoutingErrors.new(ActionController::Routing::Routes)
  end

  def test_root_path
    get '/'
    assert_success
    assert_equal({ :controller => 'homepage', :action => 'index' }, routing_args)
  end

  def test_path_with_globbing
    get '/files/images/photo.jpg'
    assert_success

    assert_equal({ :controller => 'files', :action => 'index', :files => ['images', 'photo.jpg'] }, routing_args)
  end

  def test_default_route_extracts_parameters
    get '/default/foo/bar/1.xml'
    assert_success
    assert_equal({ :controller => 'foo', :action => 'bar', :id => '1', :format => 'xml' }, routing_args)

    get '/default/foo/bar/1'
    assert_success
    assert_equal({ :controller => 'foo', :action => 'bar', :id => '1' }, routing_args)

    get '/default/foo/bar'
    assert_success
    assert_equal({ :controller => 'foo', :action => 'bar' }, routing_args)

    get '/default/foo'
    assert_success
    assert_equal({ :controller => 'foo', :action => 'index' }, routing_args)
  end

  def test_params_override_defaults
    get '/params_with_defaults/bar'
    assert_success
    assert_equal({ :controller => 'bar', :action => 'index' }, routing_args)

    get '/params_with_defaults'
    assert_success
    assert_equal({ :controller => 'foo', :action => 'index' }, routing_args)
  end

  def test_regexp
    get '/regexp/foo/bar/123'
    assert_success
    assert_equal({ :controller => 'foo', :action => 'bar', :id => '123' }, routing_args)

    get '/regexp/foos/baz/123'
    assert_success
    assert_equal({ :controller => 'foo', :action => 'baz', :id => '123' }, routing_args)

    get '/regexp/bar/abc/123'
    assert_success
    assert_equal({ :controller => 'foo', :action => 'abc', :id => '123' }, routing_args)

    get '/regexp/baz/abc/123'
    assert_success
    assert_equal({ :controller => 'foo', :action => 'index' }, routing_args)

    get '/regexp/bars/foo/baz'
    assert_not_found
  end

  def test_url_for_with_resource_named_route
    assert_equal '/people', @app.url_for(:people)
    assert_equal '/people/1', @app.url_for(:person, :id => '1')
  end
end
