module RecognitionTests
  module Nesting
    def test_path_prefix
      get '/prefix/foo/bar/1'
      assert_success
      assert_equal({ :controller => 'foo', :action => 'bar', :id => '1' }, routing_args)
      assert_equal '/foo/bar/1', @env['PATH_INFO']
      assert_equal '/prefix', @env['SCRIPT_NAME']
    end
  end
end
