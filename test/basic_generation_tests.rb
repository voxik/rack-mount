module BasicGenerationTests
  def test_url_for_with_named_route
    assert_equal "/login", @app.url_for(:login)
    assert_equal "/logout", @app.url_for(:logout)
    assert_equal "/geocode/60622", @app.url_for(:geocode, :postalcode => "60622")
  end

  def test_url_for_with_hash
    assert_equal "/login", @app.url_for(:controller => "sessions", :action => "new")
    assert_equal "/logout", @app.url_for(:controller => "sessions", :action => "destroy")
    assert_equal "/foo", @app.url_for(:controller => "foo", :action => "index")
    assert_equal "/foo/bar", @app.url_for(:controller => "foo_bar", :action => "index")
    assert_equal "/baz", @app.url_for(:controller => "baz", :action => "index")
  end
end
