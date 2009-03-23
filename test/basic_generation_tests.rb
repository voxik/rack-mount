module BasicGenerationTests
  def test_url_for_with_named_route
    assert_equal "/login", @app.url_for(:login)
    assert_equal "/logout", @app.url_for(:logout)
    assert_equal "/geocode/60622", @app.url_for(:geocode, :postalcode => "60622")

    assert_equal "/global/export", @app.url_for(:export_request)
    assert_equal "/global/hide_notice", @app.url_for(:hide_notice)
    assert_equal "/export/1/file.txt", @app.url_for(:export_download, :id => "1", :file => "file.txt")
  end

  def test_url_for_with_hash
    assert_equal "/login", @app.url_for(:controller => "sessions", :action => "new")
    assert_equal "/logout", @app.url_for(:controller => "sessions", :action => "destroy")

    assert_equal "/global/show", @app.url_for(:controller => "global", :action => "show")
    assert_equal "/global/export", @app.url_for(:controller => "global", :action => "export")
    assert_equal "/global/hide_notice", @app.url_for(:controller => "global", :action => "hide_notice")
    assert_equal "/global/export", @app.url_for(:controller => "global", :action => "export")

    assert_equal "/foo", @app.url_for(:controller => "foo", :action => "index")
    assert_equal "/foo/bar", @app.url_for(:controller => "foo_bar", :action => "index")
    assert_equal "/baz", @app.url_for(:controller => "baz", :action => "index")
  end

  def test_url_for_with_query_string
    assert_equal "/login?token=1", @app.url_for(:login, :token => "1")
    assert_equal "/login?token=1", @app.url_for(:controller => "sessions", :action => "new", :token => "1")
  end
end
