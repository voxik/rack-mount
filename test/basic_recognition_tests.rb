module BasicRecognitionTests
  def test_path
    get "/foo"
    assert_success
    assert_equal({ :controller => "foo", :action => "index" }, routing_args)

    post "/foo"
    assert_success
    assert_equal({ :controller => "foo", :action => "index" }, routing_args)

    put "/foo"
    assert_success
    assert_equal({ :controller => "foo", :action => "index" }, routing_args)

    delete "/foo"
    assert_success
    assert_equal({ :controller => "foo", :action => "index" }, routing_args)
  end

  def test_nested_path
    get "/foo/bar"
    assert_success
    assert_equal({ :controller => "foo_bar", :action => "index" }, routing_args)
  end

  def test_path_mapped_with_leading_slash
    get "/baz"
    assert_success
    assert_equal({ :controller => "baz", :action => "index" }, routing_args)
  end

  def test_path_does_get_shadowed
    get "/people"
    assert_success
    assert_equal({ :controller => "people", :action => "index" }, routing_args)

    get "/people/new"
    assert_success
    assert_equal({ :controller => "people", :action => "new" }, routing_args)
  end

  def test_root_path
    get "/"
    assert_success
    assert_equal({ :controller => "homepage" }, routing_args)
  end

  def test_extracts_parameters
    get "/foo/bar/1"
    assert_success
    assert_equal({ :controller => "foo", :action => "bar", :id => "1" },
      routing_args)

    get "/foo/bar/1.xml"
    assert_success
    assert_equal({ :controller => "foo", :action => "bar", :id => "1", :format => "xml" },
      routing_args)
  end

  def test_extracts_id
    get "/people/1"
    assert_success
    assert_equal({ :controller => "people", :action => "show", :id => "1" }, routing_args)

    put "/people/1"
    assert_success
    assert_equal({ :controller => "people", :action => "update", :id => "1" }, routing_args)

    delete "/people/1"
    assert_success
    assert_equal({ :controller => "people", :action => "destroy", :id => "1" }, routing_args)

    get "/people/2/edit"
    assert_success
    assert_equal({ :controller => "people", :action => "edit", :id => "2" }, routing_args)
  end

  def test_requirements
    get "/geocode/60614"
    assert_success
    assert_equal({ :controller => "geocode", :action => "show", :postalcode => "60614" }, routing_args)

    get "/geocode2/60614"
    assert_success
    assert_equal({ :controller => "geocode", :action => "show", :postalcode => "60614" }, routing_args)
  end

  def test_path_with_globbing
    get "/files/images/photo.jpg"
    assert_success

    # TODO
    # assert_equal({:files => ["images", "photo.jpg"]}, routing_args)
    assert_equal({ :controller => "files", :action => "index", :files => "images/photo.jpg" }, routing_args)
  end

  def test_with_controller_scope
    get "/global/index"
    assert_success
    assert_equal({ :controller => "global", :action => "index" }, routing_args)

    get "/global/show"
    assert_success
    assert_equal({ :controller => "global", :action => "show" }, routing_args)

    get "/global/export"
    assert_success
    assert_equal({ :controller => "global", :action => "export" }, routing_args)

    get "/global/hide_notice"
    assert_success
    assert_equal({ :controller => "global", :action => "hide_notice" }, routing_args)

    get "/export/1/foo"
    assert_success
    assert_equal({ :controller => "global", :action => "export", :id => "1", :file => "foo" }, routing_args)
  end

  def test_another_with_controller_scope
    get "/login"
    assert_success
    assert_equal({ :controller => "sessions", :action => "new" }, routing_args)

    post "/login"
    assert_success
    assert_equal({ :controller => "sessions", :action => "create" }, routing_args)

    get "/logout"
    assert_not_found

    delete "/logout"
    assert_success
    assert_equal({ :controller => "sessions", :action => "destroy" }, routing_args)
  end

  def test_optional_route
    get "/optional/index"
    assert_success
    assert_equal({ :controller => "optional", :action => "index" }, routing_args)

    get "/optional/index.xml"
    assert_success
    assert_equal({ :controller => "optional", :action => "index", :format => "xml" }, routing_args)
  end

  def test_namespaced_resources
    get "/account/subscription"
    assert_success
    assert_equal({ :controller => "account/subscription", :action => "index" }, routing_args)

    get "/account/credit"
    assert_success
    assert_equal({ :controller => "account/credit", :action => "index" }, routing_args)
  end

  def test_regexp
    get "/regexp/foo/bar/123"
    assert_success
    assert_equal({ :controller => "foo", :action => "bar", :id => "123" }, routing_args)

    get "/regexp/foos/baz/123"
    assert_success
    assert_equal({ :controller => "foo", :action => "baz", :id => "123" }, routing_args)

    get "/regexp/bars/foo/baz"
    assert_not_found
  end

  def test_not_found
    get "/admin/widgets/show/random"
    assert_not_found
  end
end
