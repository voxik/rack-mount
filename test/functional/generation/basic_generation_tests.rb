module BasicGenerationTests
  def test_url_for_with_named_route
    assert_equal '/login', @app.url_for(:login)
    assert_equal '/logout', @app.url_for(:logout)
    assert_equal '/geocode/60622', @app.url_for(:geocode, :postalcode => '60622')
    assert_equal '/', @app.url_for(:root)

    assert_equal '/people/1', @app.url_for(:person, :id => '1')
    assert_equal '/people/%231', @app.url_for(:person, :id => '#1')
    assert_equal '/people/number%20one', @app.url_for(:person, :id => 'number one')

    assert_equal '/global/export', @app.url_for(:export_request)
    assert_equal '/global/hide_notice', @app.url_for(:hide_notice)
    assert_equal '/export/1/file.txt', @app.url_for(:export_download, :id => '1', :file => 'file.txt')

    assert_equal '/regexp/bar/abc/123', @app.url_for(:complex_regexp, :action => 'abc', :id => '123')
    assert_equal nil, @app.url_for(:complex_regexp_fail)

    assert_equal '/prefix', @app.url_for(:prefix)
  end

  def test_url_for_with_hash
    assert_equal '/login', @app.url_for(:controller => 'sessions', :action => 'new')
    assert_equal '/logout', @app.url_for(:controller => 'sessions', :action => 'destroy')

    assert_equal '/global/show', @app.url_for(:controller => 'global', :action => 'show')
    assert_equal '/global/export', @app.url_for(:controller => 'global', :action => 'export')

    assert_equal '/account2', @app.url_for(:controller => 'account2', :action => 'subscription')
    assert_equal '/account2/billing', @app.url_for(:controller => 'account2', :action => 'billing')

    assert_equal '/foo', @app.url_for(:controller => 'foo', :action => 'index')
    assert_equal '/foo/bar', @app.url_for(:controller => 'foo_bar', :action => 'index')
    assert_equal '/baz', @app.url_for(:controller => 'baz', :action => 'index')

    assert_equal '/ws/foo', @app.url_for(:ws => true, :controller => 'foo')
    assert_equal '/ws/foo/list', @app.url_for(:ws => true, :controller => 'foo', :action => 'list')

    assert_equal '/params_with_defaults', @app.url_for(:params_with_defaults => true, :controller => 'foo')
    assert_equal '/params_with_defaults/bar', @app.url_for(:params_with_defaults => true, :controller => 'bar')

    assert_equal '/pages/1/users/show/2', @app.url_for(:page_id => '1', :controller => 'users', :action => 'show', :id => '2')
    assert_equal '/default/users/show/1', @app.url_for(:controller => 'users', :action => 'show', :id => '1')
    assert_equal '/default/users/show/1', @app.url_for({:action => 'show', :id => '1'}, {:controller => 'users'})
  end

  def test_url_for_with_query_string
    assert_equal '/login?token=1', @app.url_for(:login, :token => '1')
    assert_equal '/login?token=1', @app.url_for(:controller => 'sessions', :action => 'new', :token => '1')
  end

  def test_uses_default_parameters_when_non_are_passed
    assert_equal '/feed/atom', @app.url_for(:feed, :kind => 'atom')
    assert_equal '/feed/rss', @app.url_for(:feed)
  end
end
