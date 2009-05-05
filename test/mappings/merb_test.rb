# Latest version of Merb isn't 1.9 compatible yet
if RUBY_VERSION < '1.9'
  require 'test_helper'
  require 'rack/mount/mappers/merb'

  class MerbApiTest < Test::Unit::TestCase
    include TestHelper
    include BasicRecognitionTests

    Router = Rack::Mount::RouteSet.new
    Router.prepare do
      # TODO: DRY up with resource helper
      with(:controller => 'people') do
        match('/people', :method => :get).to(:action => 'index')
        match('/people', :method => :post).to(:action => 'create')
        match('/people/new', :method => :get).to(:action => 'new')
        match('/people/:id/edit', :method => :get).to(:action => 'edit')
        match('/people/:id', :method => :get).to(:action => 'show')
        match('/people/:id', :method => :put).to(:action => 'update')
        match('/people/:id', :method => :delete).to(:action => 'destroy')
      end

      match('').to(:controller => 'homepage')

      with(:controller => 'geocode') do
        match('geocode/:postalcode', :postalcode => /\d{5}(-\d{4})?/).to(:action => 'show')
        match('geocode2/:postalcode', :postalcode => /\d{5}(-\d{4})?/).to(:action => 'show')
      end

      with(:controller => 'sessions') do
        match('/login',  :method => :get).to(:action => 'new')
        match('/login',  :method => :post).to(:action => 'create')
        match('/logout', :method => :delete).to(:action => 'destroy')
      end

      with(:controller => 'global') do
        match('global/:action').register
        match('global/export').to(:action => 'export')
        match('global/hide_notice').to(:action => 'hide_notice')
        match('/export/:id/:file', :file => /.*/).to(:action => 'export')
      end

      # TODO: DRY up with namespace helper and resources
      with(:controller => 'account/subscription') do
        match('/account/subscription', :method => :get).to(:action => 'index')
        match('/account/subscription', :method => :post).to(:action => 'create')
        match('/account/subscription/new', :method => :get).to(:action => 'new')
        match('/account/subscription/:id/edit', :method => :get).to(:action => 'edit')
        match('/account/subscription/:id', :method => :get).to(:action => 'show')
        match('/account/subscription/:id', :method => :put).to(:action => 'update')
        match('/account/subscription/:id', :method => :delete).to(:action => 'destroy')
      end

      # TODO: DRY up with namespace helper and resources
      with(:controller => 'account/credit') do
        match('/account/credit', :method => :get).to(:action => 'index')
        match('/account/credit', :method => :post).to(:action => 'create')
        match('/account/credit/new', :method => :get).to(:action => 'new')
        match('/account/credit/:id/edit', :method => :get).to(:action => 'edit')
        match('/account/credit/:id', :method => :get).to(:action => 'show')
        match('/account/credit/:id', :method => :put).to(:action => 'update')
        match('/account/credit/:id', :method => :delete).to(:action => 'destroy')
      end

      # TODO: DRY up with namespace helper and resources
      with(:controller => 'account/credit_card') do
        match('/account/credit_card', :method => :get).to(:action => 'index')
        match('/account/credit_card', :method => :post).to(:action => 'create')
        match('/account/credit_card/new', :method => :get).to(:action => 'new')
        match('/account/credit_card/:id/edit', :method => :get).to(:action => 'edit')
        match('/account/credit_card/:id', :method => :get).to(:action => 'show')
        match('/account/credit_card/:id', :method => :put).to(:action => 'update')
        match('/account/credit_card/:id', :method => :delete).to(:action => 'destroy')
      end

      match('foo').to(:controller => 'foo', :action => 'index')
      match('foo/bar').to(:controller => 'foo_bar', :action => 'index')
      match('/baz').to(:controller => 'baz', :action => 'index')

      match('/optional/index(.:format)').to(:controller => 'optional', :action => 'index')

      match(%r{^/regexp/foos?/(?:<action>bar|baz)/(?:<id>[a-z0-9]+)$}).to(:controller => 'foo')
      match(%r{^/regexp/bar/(?:<action>[a-z]+)/(?:<id>[0-9]+)$}).to(:controller => 'foo')
      match(%r{^/regexp/baz/[a-z]+/[0-9]+$}).to(:controller => 'foo')

      match('defer').defer_to do |request, params|
        params[:controller] = 'defer'
      end

      match('defer_no_match').defer_to do |request, params|
        false
      end

      match(:path => '/referer', :referer => 'http://www.google.com/').to(:controller => 'search', :action => 'index')

      match('files/*files').to(:controller => 'files', :action => 'index')
      match('params_with_defaults(/:controller)').to(:controller => 'foo')
      match('default/:controller(/:action(/:id(.:format)))').to()
      match(:method => :delete).to(:controller => 'global', :action => 'destroy')
    end

    def setup
      @app = Router
    end

    def test_defer
      get '/defer'
      assert_success
      assert_equal({ :controller => 'defer' }, routing_args)

      get '/defer_no_match'
      assert_not_found
    end

    def test_request_conditions
      get '/referer', 'HTTP_REFERER' => 'http://www.google.com/'
      assert_success
      assert_equal({ :controller => 'search', :action => 'index' }, routing_args)

      get '/referer', 'HTTP_REFERER' => 'http://www.yahoo.com/'
      assert_not_found
    end
  end
end
