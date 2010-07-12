require 'abstract_unit'

class TestPrefix < Test::Unit::TestCase
  Prefix = Rack::Mount::Prefix

  def test_path_prefix_shifting
    @app = Prefix.new(EchoApp, '/foo')

    get '/foo/bar'
    assert_success
    assert_equal '/bar', env['PATH_INFO']
    assert_equal '/foo', env['SCRIPT_NAME']
  end

  def test_path_prefix_restores_original_path_when_it_leaves_the_scope
    @app = Prefix.new(EchoApp, '/foo')
    env = {'PATH_INFO' => '/foo/bar', 'SCRIPT_NAME' => ''}
    @app.call(env)
    assert_equal({'PATH_INFO' => '/foo/bar', 'SCRIPT_NAME' => ''}, env)
  end

  def test_path_prefix_shifting_doesnt_normalize_path
    @app = Prefix.new(EchoApp, '/foo')

    get '/foo/bar'
    assert_success
    assert_equal '/bar', env['PATH_INFO']
    assert_equal '/foo', env['SCRIPT_NAME']

    get '/foo/bar/'
    assert_success
    assert_equal '/bar/', env['PATH_INFO']
    assert_equal '/foo', env['SCRIPT_NAME']
  end

  def test_path_prefix_shifting_with_root
    @app = Prefix.new(EchoApp, '/foo')

    get '/foo'
    assert_success
    assert_equal '', env['PATH_INFO']
    assert_equal '/foo', env['SCRIPT_NAME']
  end
end
