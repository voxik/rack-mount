require 'test_helper'
require 'rack/mount/mappers/simple'

class SimpleApiTest < Test::Unit::TestCase
  include TestHelper
  include BasicRecognitionTests

  Routes = Rack::Mount::RouteSet.new
  Routes.prepare do |r|
    r.map '/people', :get, :to => EchoApp, :with => { :controller => 'people', :action => 'index' }
    r.map '/people', :post, :to => EchoApp, :with => { :controller => 'people', :action => 'create' }
    r.map '/people/new', :get, :to => EchoApp, :with => { :controller => 'people', :action => 'new' }
    r.map '/people/:id/edit', :get, :to => EchoApp, :with => { :controller => 'people', :action => 'edit' }
    r.map '/people/:id', :get, :to => EchoApp, :with => { :controller => 'people', :action => 'show' }
    r.map '/people/:id', :put, :to => EchoApp, :with => { :controller => 'people', :action => 'update' }
    r.map '/people/:id', :delete, :to => EchoApp, :with => { :controller => 'people', :action => 'destroy' }

    r.map '/', :to => EchoApp, :with => { :controller => 'homepage' }

    r.map '/geocode/:postalcode', :to => EchoApp, :postalcode => /\d{5}(-\d{4})?/, :name => :geocode, :with => { :controller => 'geocode', :action => 'show' }
    r.map '/geocode2/:postalcode', :to => EchoApp, :postalcode => /\d{5}(-\d{4})?/, :name => :geocode2, :with => { :controller => 'geocode', :action => 'show' }

    r.map '/login', :get, :to => EchoApp, :name => :login, :with => { :controller => 'sessions', :action => 'new' }
    r.map '/login', :post, :to => EchoApp, :with => { :controller => 'sessions', :action => 'create' }
    r.map '/logout', :delete, :to => EchoApp, :name => :logout, :with => { :controller => 'sessions', :action => 'destroy' }

    r.map '/global/:action', :to => EchoApp, :with => { :controller => 'global' }
    r.map '/global/export', :to => EchoApp, :name => :export_request, :with => { :controller => 'global', :action => 'export' }
    r.map '/global/hide_notice', :to => EchoApp, :name => :hide_notice, :with => { :controller => 'global', :action => 'hide_notice' }
    r.map '/export/:id/:file', :to => EchoApp, :name => :export_download, :with => { :controller => 'global', :action => 'export' }, :requirements => { :file => /.*/ }

    r.map '/account/subscription', :get, :to => EchoApp, :with => { :controller => 'account/subscription', :action => 'index' }
    r.map '/account/subscription', :post, :to => EchoApp, :with => { :controller => 'account/subscription', :action => 'create' }
    r.map '/account/subscription/new', :get, :to => EchoApp, :with => { :controller => 'account/subscription', :action => 'new' }
    r.map '/account/subscription/:id/edit', :get, :to => EchoApp, :with => { :controller => 'account/subscription', :action => 'edit' }
    r.map '/account/subscription/:id', :get, :to => EchoApp, :with => { :controller => 'account/subscription', :action => 'show' }
    r.map '/account/subscription/:id', :put, :to => EchoApp, :with => { :controller => 'account/subscription', :action => 'update' }
    r.map '/account/subscription/:id', :delete, :to => EchoApp, :with => { :controller => 'account/subscription', :action => 'destroy' }

    r.map '/account/credit', :get, :to => EchoApp, :with => { :controller => 'account/credit', :action => 'index' }
    r.map '/account/credit', :post, :to => EchoApp, :with => { :controller => 'account/credit', :action => 'create' }
    r.map '/account/credit/new', :get, :to => EchoApp, :with => { :controller => 'account/credit', :action => 'new' }
    r.map '/account/credit/:id/edit', :get, :to => EchoApp, :with => { :controller => 'account/credit', :action => 'edit' }
    r.map '/account/credit/:id', :get, :to => EchoApp, :with => { :controller => 'account/credit', :action => 'show' }
    r.map '/account/credit/:id', :put, :to => EchoApp, :with => { :controller => 'account/credit', :action => 'update' }
    r.map '/account/credit/:id', :delete, :to => EchoApp, :with => { :controller => 'account/credit', :action => 'destroy' }

    r.map '/account/credit_card', :get, :to => EchoApp, :with => { :controller => 'account/credit_card', :action => 'index' }
    r.map '/account/credit_card', :post, :to => EchoApp, :with => { :controller => 'account/credit_card', :action => 'create' }
    r.map '/account/credit_card/new', :get, :to => EchoApp, :with => { :controller => 'account/credit_card', :action => 'new' }
    r.map '/account/credit_card/:id/edit', :get, :to => EchoApp, :with => { :controller => 'account/credit_card', :action => 'edit' }
    r.map '/account/credit_card/:id', :get, :to => EchoApp, :with => { :controller => 'account/credit_card', :action => 'show' }
    r.map '/account/credit_card/:id', :put, :to => EchoApp, :with => { :controller => 'account/credit_card', :action => 'update' }
    r.map '/account/credit_card/:id', :delete, :to => EchoApp, :with => { :controller => 'account/credit_card', :action => 'destroy' }

    r.map 'foo', :to => EchoApp, :with => { :controller => 'foo', :action => 'index' }
    r.map 'foo/bar', :to => EchoApp, :with => { :controller => 'foo_bar', :action => 'index' }
    r.map '/baz', :to => EchoApp, :with => { :controller => 'baz', :action => 'index' }

    r.map '/optional/index(.:format)', :to => EchoApp, :with => { :controller => 'optional', :action => 'index' }

    if Rack::Mount::Const::SUPPORTS_NAMED_CAPTURES
      regexp = eval('%r{^/regexp/foos?/(?<action>bar|baz)/(?<id>[a-z0-9]+)}')
      r.map regexp, :to => EchoApp, :with => { :controller => 'foo' }

      regexp = eval('%r{^/regexp/bar/(?<action>[a-z]+)/(?<id>[0-9]+)$}')
      r.map regexp, :to => EchoApp, :name => :complex_regexp, :with => { :controller => 'foo' }
    else
      r.map %r{^/regexp/foos?/(?:<action>bar|baz)/(?:<id>[a-z0-9]+)}, :to => EchoApp, :with => { :controller => 'foo' }
      r.map %r{^/regexp/bar/(?:<action>[a-z]+)/(?:<id>[0-9]+)$}, :to => EchoApp, :name => :complex_regexp, :with => { :controller => 'foo' }
    end
    r.map %r{^/regexp/baz/[a-z]+/[0-9]+$}, :to => EchoApp, :name => :complex_regexp_fail, :with => { :controller => 'foo' }

    r.map 'files/*files', :to => EchoApp, :with => { :controller => 'files', :action => 'index' }

    r.map %r{^/prefix/.*$}, :to => Rack::Mount::PathPrefix.new(DefaultSet, '/prefix')

    r.map 'params_with_defaults(/:controller)', :to => EchoApp, :with => { :controller => 'foo' }
    r.map 'default/:controller(/:action(/:id(.:format)))', :to => EchoApp
    r.map nil, :delete, :to => EchoApp, :with => { :controller => 'global', :action => 'destroy' }
  end

  def setup
    @app = Routes
  end
end
