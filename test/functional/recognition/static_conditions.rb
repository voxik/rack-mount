module RecognitionTests
  module StaticConditions
    # add_route(EchoApp, { :path_info => 'foo' }, { :controller => 'foo', :action => 'index' })
    def test_path
      get '/foo'
      assert_success
      assert_equal({ :controller => 'foo', :action => 'index' }, routing_args)

      post '/foo'
      assert_success
      assert_equal({ :controller => 'foo', :action => 'index' }, routing_args)

      put '/foo'
      assert_success
      assert_equal({ :controller => 'foo', :action => 'index' }, routing_args)

      delete '/foo'
      assert_success
      assert_equal({ :controller => 'foo', :action => 'index' }, routing_args)
    end

    # add_route(EchoApp, { :path_info => 'foo/bar' }, { :controller => 'foo_bar', :action => 'index' })
    def test_nested_path
      get '/foo/bar'
      assert_success
      assert_equal({ :controller => 'foo_bar', :action => 'index' }, routing_args)
    end

    # add_route(EchoApp, { :path_info => '/baz' }, { :controller => 'baz', :action => 'index' })
    def test_path_mapped_with_leading_slash
      get '/baz'
      assert_success
      assert_equal({ :controller => 'baz', :action => 'index' }, routing_args)
    end

    # add_route(EchoApp, { :path_info => '/people', :request_method => 'GET' }, { :controller => 'people', :action => 'index' })
    # add_route(EchoApp, { :path_info => '/people', :request_method => 'POST' }, { :controller => 'people', :action => 'create' })
    # add_route(EchoApp, { :path_info => '/people/new', :request_method => 'GET' }, { :controller => 'people', :action => 'new' })
    def test_path_does_get_shadowed
      get '/people'
      assert_success
      assert_equal({ :controller => 'people', :action => 'index' }, routing_args)

      get '/people/new'
      assert_success
      assert_equal({ :controller => 'people', :action => 'new' }, routing_args)
    end

    # add_route(EchoApp, { :path_info => '/' }, { :controller => 'homepage' }, :root)
    def test_root_path
      get '/'
      assert_success
      assert_equal({ :controller => 'homepage' }, routing_args)
    end

    # add_route(EchoApp, { :path_info => '/login', :request_method => 'GET' }, { :controller => 'sessions', :action => 'new' }, :login)
    # add_route(EchoApp, { :path_info => '/login', :request_method => 'POST' }, { :controller => 'sessions', :action => 'create' })
    # add_route(EchoApp, { :path_info => '/logout', :request_method => 'DELETE' }, { :controller => 'sessions', :action => 'destroy' }, :logout)
    def test_another_with_controller_scope
      get '/login'
      assert_success
      assert_equal({ :controller => 'sessions', :action => 'new' }, routing_args)

      post '/login'
      assert_success
      assert_equal({ :controller => 'sessions', :action => 'create' }, routing_args)

      get '/logout'
      assert_not_found

      delete '/logout'
      assert_success
      assert_equal({ :controller => 'sessions', :action => 'destroy' }, routing_args)
    end

    # add_route(EchoApp, { :request_method => 'DELETE' }, { :controller => 'global', :action => 'destroy' }
    def test_only_method_condition
      delete '/all'
      assert_success
      assert_equal({ :controller => 'global', :action => 'destroy' }, routing_args)

      get '/all'
      assert_not_found
    end

    def test_schema_condition
      get '/ssl', 'rack.url_scheme' => 'http'
      assert_success
      assert_equal({ :controller => 'ssl', :action => 'nonssl' }, routing_args)

      get '/ssl', 'rack.url_scheme' => 'https'
      assert_success
      assert_equal({ :controller => 'ssl', :action => 'ssl' }, routing_args)
    end

    def test_host_condition
      get '/host', 'HTTP_HOST' => '37s.backpackit.com'
      assert_success
      assert_equal({ :controller => 'account', :account => '37s' }, routing_args)

      get '/host', 'HTTP_HOST' => 'josh.backpackit.com'
      assert_success
      assert_equal({ :controller => 'account', :account => 'josh' }, routing_args)

      get '/host', 'HTTP_HOST' => 'nil.backpackit.com'
      assert_not_found
    end

    # set.add_route(EchoApp, { :path_info => '/slashes/trailing/' }, { :controller => 'slash', :action => 'trailing' })
    # set.add_route(EchoApp, { :path_info => '//slashes/repeated' }, { :controller => 'slash', :action => 'repeated' })
    def test_slashes
      get '/slashes/trailing/'
      assert_success
      assert_equal({ :controller => 'slash', :action => 'trailing' }, routing_args)

      get '/slashes/trailing'
      assert_success
      assert_equal({ :controller => 'slash', :action => 'trailing' }, routing_args)

      get '/slashes/repeated'
      assert_success
      assert_equal({ :controller => 'slash', :action => 'repeated' }, routing_args)
    end

    def test_path_prefix
      get '/prefix/foo/bar/1'
      assert_success
      assert_equal({ :controller => 'foo', :action => 'bar', :id => '1' }, routing_args)
      assert_equal '/foo/bar/1', @env['PATH_INFO']
      assert_equal '/prefix', @env['SCRIPT_NAME']
    end

    def test_not_found
      get '/admin/widgets/show/random'
      assert_not_found
    end
  end
end
