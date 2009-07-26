module RecognitionTests
  module Captures
    # add_route(EchoApp, { :path_info => %r{^/people/(?<id>[a-z0-9]+)/edit$}, :request_method => 'GET' }, { :controller => 'people', :action => 'edit' })
    # add_route(EchoApp, { :path_info => %r{^/people/(?<id>[a-z0-9]+)$}, :request_method => 'GET' }, { :controller => 'people', :action => 'show' })
    # add_route(EchoApp, { :path_info => %r{^/people/(?<id>[a-z0-9]+)$}, :request_method => 'PUT' }, { :controller => 'people', :action => 'update' })
    # add_route(EchoApp, { :path_info => %r{^/people/(?<id>[a-z0-9]+)$}, :request_method => 'DELETE' }, { :controller => 'people', :action => 'destroy' })
    def test_extracts_id
      get '/people/1'
      assert_success
      assert_equal({ :controller => 'people', :action => 'show', :id => '1' }, routing_args)

      put '/people/1'
      assert_success
      assert_equal({ :controller => 'people', :action => 'update', :id => '1' }, routing_args)

      delete '/people/1'
      assert_success
      assert_equal({ :controller => 'people', :action => 'destroy', :id => '1' }, routing_args)

      get '/people/2/edit'
      assert_success
      assert_equal({ :controller => 'people', :action => 'edit', :id => '2' }, routing_args)
    end

    # add_route(EchoApp, { :path_info => %r{^/geocode/(?<postalcode>\d{5}(-\d{4})?)$} }, { :controller => 'geocode', :action => 'show' }, :geocode)
    # add_route(EchoApp, { :path_info => %r{^/geocode2/(?<postalcode>\d{5}(-\d{4})?)$} }, { :controller => 'geocode', :action => 'show' }, :geocode2)
    def test_requirements
      get '/geocode/60614'
      assert_success
      assert_equal({ :controller => 'geocode', :action => 'show', :postalcode => '60614' }, routing_args)

      get '/geocode2/60614'
      assert_success
      assert_equal({ :controller => 'geocode', :action => 'show', :postalcode => '60614' }, routing_args)
    end

    # add_route(EchoApp, { :path_info => %r{^/files/(?<files>.*)$} }, { :controller => 'files', :action => 'index' })
    def test_path_with_globbing
      get '/files/images/photo.jpg'
      assert_success

      assert_equal({ :controller => 'files', :action => 'index', :files => 'images/photo.jpg' }, routing_args)
    end

    # add_route(EchoApp, { :path_info => %r{^/global/(?<action>[a-z0-9]+)$} }, { :controller => 'global' })
    # add_route(EchoApp, { :path_info => '/global/export' }, { :controller => 'global', :action => 'export' }, :export_request)
    # add_route(EchoApp, { :path_info => '/global/hide_notice' }, { :controller => 'global', :action => 'hide_notice' }, :hide_notice)
    # add_route(EchoApp, { :path_info => %r{^/export/(?<id>[a-z0-9]+)/(?<file>.*)$} }, { :controller => 'global', :action => 'export' }, :export_download)
    def test_with_controller_scope
      get '/global/index'
      assert_success
      assert_equal({ :controller => 'global', :action => 'index' }, routing_args)

      get '/global/show'
      assert_success
      assert_equal({ :controller => 'global', :action => 'show' }, routing_args)

      get '/global/export'
      assert_success
      assert_equal({ :controller => 'global', :action => 'export' }, routing_args)

      get '/global/hide_notice'
      assert_success
      assert_equal({ :controller => 'global', :action => 'hide_notice' }, routing_args)

      get '/export/1/foo'
      assert_success
      assert_equal({ :controller => 'global', :action => 'export', :id => '1', :file => 'foo' }, routing_args)
    end

    # add_route(EchoApp, { :path_info => %r{^/optional/index(\.(?<format>[a-z]+))?$} }, { :controller => 'optional', :action => 'index' })
    def test_optional_route
      get '/optional/index'
      assert_success
      assert_equal({ :controller => 'optional', :action => 'index' }, routing_args)

      get '/optional/index.xml'
      assert_success
      assert_equal({ :controller => 'optional', :action => 'index', :format => 'xml' }, routing_args)
    end

    # add_route(EchoApp, { :path_info => '/account/subscription', :request_method => 'GET' }, { :controller => 'account/subscription', :action => 'index' })
    # add_route(EchoApp, { :path_info => '/account/credit', :request_method => 'GET' }, { :controller => 'account/credit', :action => 'index' })
    def test_namespaced_resources
      get '/account/subscription'
      assert_success
      assert_equal({ :controller => 'account/subscription', :action => 'index' }, routing_args)

      get '/account/credit'
      assert_success
      assert_equal({ :controller => 'account/credit', :action => 'index' }, routing_args)
    end

    # add_route(EchoApp, { :path_info => %r{^/regexp/foos?/(?<action>bar|baz)/(?<id>[a-z0-9]+)$} }, { :controller => 'foo' })
    # add_route(EchoApp, { :path_info => %r{^/regexp/bar/(?<action>[a-z]+)/(?<id>[0-9]+)$} }, { :controller => 'foo' }, :complex_regexp)
    # add_route(EchoApp, { :path_info => %r{^/regexp/baz/[a-z]+/[0-9]+$} }, { :controller => 'foo' }, :complex_regexp_fail)
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
      assert_equal({ :controller => 'foo' }, routing_args)

      get '/regexp/bars/foo/baz'
      assert_not_found
    end

    def test_unnamed_capture
      get '/death/star'
      assert_success
      assert_equal({ :controller => 'star' }, routing_args)

      get '/new/death/star'
      assert_success
      assert_equal({ :controller => 'star' }, routing_args)

      get '/death.wsdl/star'
      assert_success
      assert_equal({ :controller => 'star' }, routing_args)
    end

    def test_method_regexp
      get '/method'
      assert_success
      assert_equal({ :controller => 'method', :action => 'index' }, routing_args)

      post '/method'
      assert_success
      assert_equal({ :controller => 'method', :action => 'index' }, routing_args)

      put '/method'
      assert_not_found
    end
  end
end
