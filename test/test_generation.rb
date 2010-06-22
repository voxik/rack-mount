# encoding: utf-8
require 'abstract_unit'
require 'fixtures/basic_set'

class TestGeneration < Test::Unit::TestCase
  def setup
    @env = Rack::MockRequest.env_for('/')
    @app = BasicSet
    assert !set_included_modules.include?(Rack::Mount::CodeGeneration)
  end

  def test_url_with_named_route
    assert_equal '/login', @app.url(@env, :login, :only_path => true)
    assert_equal '/logout', @app.url(@env, :logout, :only_path => true)
    assert_equal '/geocode/60622', @app.url(@env, :geocode, :postalcode => '60622', :only_path => true)
    assert_equal '/', @app.url(@env, :root, :only_path => true)

    assert_equal '/people/1', @app.url(@env, :person, :id => '1', :only_path => true)
    assert_equal '/people/%231', @app.url(@env, :person, :id => '#1', :only_path => true)
    assert_equal '/people/number%20one', @app.url(@env, :person, :id => 'number one', :only_path => true)

    assert_equal '/global/export', @app.url(@env, :export_request, :only_path => true)
    assert_equal '/global/hide_notice', @app.url(@env, :hide_notice, :only_path => true)
    assert_equal '/export/1/file.txt', @app.url(@env, :export_download, :id => '1', :file => 'file.txt', :only_path => true)

    assert_equal '/pages/1/posts', @app.url(@env, :page, :page_id => '1', :controller => 'posts', :only_path => true)
    assert_equal '/pages/1/posts/show', @app.url(@env, :page, :page_id => '1', :controller => 'posts', :action => 'show', :only_path => true)
    assert_equal '/pages/1/posts/show/2', @app.url(@env, :page, :page_id => '1', :controller => 'posts', :action => 'show', :id => '2', :only_path => true)
    assert_equal '/pages/1/posts/show/2.xml', @app.url(@env, :page, :page_id => '1', :controller => 'posts', :action => 'show', :id => '2', :format => 'xml', :only_path => true)
    assert_equal nil, @app.url(@env, :page, :page_id => '1')

    assert_equal '/ignorecase/josh', @app.url(@env, :ignore, :name => 'josh', :only_path => true)

    assert_equal '/regexp/bar/abc/123', @app.url(@env, :complex_regexp, :action => 'abc', :id => '123', :only_path => true)
    assert_equal nil, @app.url(@env, :complex_regexp_fail, :only_path => true)

    assert_equal '/prefix', @app.url(@env, :prefix, :only_path => true)
  end

  def test_url_with_hash
    assert_equal '/login', @app.url(@env, :controller => 'sessions', :action => 'new', :only_path => true)
    assert_equal '/logout', @app.url(@env, :controller => 'sessions', :action => 'destroy', :only_path => true)

    assert_equal '/global/show', @app.url(@env, :controller => 'global', :action => 'show', :only_path => true)
    assert_equal '/global/export', @app.url(@env, :controller => 'global', :action => 'export', :only_path => true)

    assert_equal '/account2', @app.url(@env, :controller => 'account2', :action => 'subscription', :only_path => true)
    assert_equal '/account2/billing', @app.url(@env, :controller => 'account2', :action => 'billing', :only_path => true)

    assert_equal '/foo', @app.url(@env, :controller => 'foo', :action => 'index', :only_path => true)
    assert_equal '/foo/bar', @app.url(@env, :controller => 'foo_bar', :action => 'index', :only_path => true)
    assert_equal '/baz', @app.url(@env, :controller => 'baz', :action => 'index', :only_path => true)

    assert_equal '/xhr', @app.url(@env, :controller => 'xhr', :only_path => true)

    assert_equal '/ws/foo', @app.url(@env, :ws => true, :controller => 'foo', :only_path => true)
    assert_equal '/ws/foo/list', @app.url(@env, :ws => true, :controller => 'foo', :action => 'list', :only_path => true)

    assert_equal '/params_with_defaults', @app.url(@env, :params_with_defaults => true, :controller => 'foo', :only_path => true)
    assert_equal '/params_with_defaults/bar', @app.url(@env, :params_with_defaults => true, :controller => 'bar', :only_path => true)

    assert_equal ['/pages/1/users/show/2', {}], @app.generate(:path_info, :page_id => '1', :controller => 'users', :action => 'show', :id => '2')
    assert_equal ['/default/users/show/1', {}], @app.generate(:path_info, :controller => 'users', :action => 'show', :id => '1')
    assert_equal ['/default/users/show/1', {}], @app.generate(:path_info, {:action => 'show', :id => '1'}, {:controller => 'users'})
    assert_equal ['/default/users/show/1', {}], @app.generate(:path_info, {:controller => 'users', :id => '1'}, {:action => 'show'})

    assert_raise(Rack::Mount::RoutingError) { @app.url(@env, {}) }
  end

  def test_generate_host
    assert_equal ['josh.backpackit.com', {}], @app.generate(:host, :controller => 'account', :account => 'josh')
    assert_equal [{:host => 'josh.backpackit.com', :path_info => '/host'}, {}], @app.generate(:all, :controller => 'account', :account => 'josh')
    assert_equal [{:request_method => 'GET', :path_info => '/login'}, {}], @app.generate(:all, :login)
    assert_equal 'http://josh.backpackit.com/host', @app.url(@env, :controller => 'account', :account => 'josh')
  end

  def test_generate_full_url
    assert_equal ['http://example.com/full/bar', {}], @app.generate(:url, :full_url, :scheme => 'http', :host => 'example.com', :foo => 'bar')
  end

  def test_does_not_mutuate_params
    assert_equal 'http://example.org/login', @app.url(@env, {:controller => 'sessions', :action => 'new'}.freeze)
    assert_equal ['josh.backpackit.com', {}], @app.generate(:host, {:controller => 'account', :account => 'josh'}.freeze)
  end

  def test_url_with_query_string
    assert_equal '/login?token=1', @app.url(@env, :login, :token => '1', :only_path => true)
    assert_equal '/login?token=1', @app.url(@env, :controller => 'sessions', :action => 'new', :token => '1', :only_path => true)
    assert_equal '/login?token[]=1&token[]=2', @app.url(@env, :login, :token => ['1', '2'], :only_path => true)
  end

  def test_uses_default_parameters_when_non_are_passed
    assert_equal 'http://example.org/feed/atom', @app.url(@env, :feed, :kind => 'atom')
    assert_equal 'http://example.org/feed/rss', @app.url(@env, :feed, :kind => 'rss')
    assert_equal 'http://example.org/feed/rss', @app.url(@env, :feed)

    assert_equal 'http://example.org/feed2.atom', @app.url(@env, :feed2, :format => 'atom')
    assert_equal 'http://example.org/feed2', @app.url(@env, :feed2, :format => 'rss')
    assert_equal 'http://example.org/feed2', @app.url(@env, :feed2)
  end

  def test_uri_escaping
    assert_equal '/uri_escaping/foo', @app.url(@env, :controller => 'uri_escaping', :value => 'foo', :only_path => true)
    assert_equal '/uri_escaping/foo%20bar', @app.url(@env, :controller => 'uri_escaping', :value => 'foo bar', :only_path => true)
    assert_equal '/uri_escaping/foo%20bar', @app.url(@env, :controller => 'uri_escaping', :value => 'foo%20bar', :only_path => true)
    assert_equal '/uri_escaping/%E2%88%9E', @app.url(@env, :controller => 'uri_escaping', :value => '∞', :only_path => true)
    assert_equal '/uri_escaping/%E2%88%9E', @app.url(@env, :controller => 'uri_escaping', :value => '%E2%88%9E', :only_path => true)
  end

  def test_regexp_parse_caching
    @app = Rack::Mount::RouteSet.new do |set|
      set.add_route(EchoApp, :path_info => Rack::Mount::Strexp.compile('/foo/:bar'))
      set.add_route(EchoApp, :path_info => Rack::Mount::Strexp.compile('/foo/:baz'))
    end

    assert_equal 'http://example.org/foo/1', @app.url(@env, :bar => '1')
    assert_equal 'http://example.org/foo/1', @app.url(@env, :baz => '1')
  end

  def test_generate_with_script_name
    @env['SCRIPT_NAME'] = '/blog'
    assert_equal 'http://example.org/blog/login', @app.url(@env, :login)
  end
end

class TestOptimizedGeneration < TestGeneration
  def setup
    @env = Rack::MockRequest.env_for('/')
    @app = OptimizedBasicSet
    assert set_included_modules.include?(Rack::Mount::CodeGeneration)
  end
end

class TestLinearGeneration < TestGeneration
  def setup
    @env = Rack::MockRequest.env_for('/')
    @app = LinearBasicSet
  end
end
