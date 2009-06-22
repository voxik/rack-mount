module RecognitionTests
  module OptionalCaptures
    # add_route(EchoApp, :path_info => %r{^/default/(?<controller>[a-z0-9]+)(/(?<action>[a-z0-9]+)(/(?<id>[a-z0-9]+)(\.(?<format>[a-z]+))?)?)?$})
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
      assert_equal({ :controller => 'foo' }, routing_args)
    end

    # add_route(EchoApp, { :path_info => %r{^/params_with_defaults(/(?<controller>[a-z0-9]+))?$} }, { :controller => 'foo' })
    def test_params_override_defaults
      get '/params_with_defaults/bar'
      assert_success
      assert_equal({ :prefix => 'params_with_defaults', :controller => 'bar' }, routing_args)

      get '/params_with_defaults'
      assert_success
      assert_equal({ :prefix => 'params_with_defaults', :controller => 'foo' }, routing_args)
    end
  end
end
