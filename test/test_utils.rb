require 'abstract_unit'

class TestUtils < Test::Unit::TestCase
  include Rack::Mount::Utils

  def test_normalize_path
    assert_equal '/foo', normalize_path('/foo')
    assert_equal '/foo', normalize_path('/foo/')
    assert_equal '/foo', normalize_path('foo')
    assert_equal '/', normalize_path('')
  end

  def test_pop_trailing_nils
    assert_equal [1, 2, 3], pop_trailing_blanks!([1, 2, 3])
    assert_equal [1, 2, 3], pop_trailing_blanks!([1, 2, 3, nil, nil])
    assert_equal [1, 2, 3], pop_trailing_blanks!([1, 2, 3, nil, ''])
    assert_equal [], pop_trailing_blanks!([nil])
    assert_equal [], pop_trailing_blanks!([''])
  end

  def test_build_nested_query
    assert_equal 'foo', build_nested_query('foo' => nil)
    assert_equal 'foo=', build_nested_query('foo' => '')
    assert_equal 'foo=bar', build_nested_query('foo' => 'bar')
    assert_equal 'foo=1&bar=2', build_nested_query('foo' => '1', 'bar' => '2')
    assert_equal 'my+weird+field=q1%212%22%27w%245%267%2Fz8%29%3F',
      build_nested_query('my weird field' => 'q1!2"\'w$5&7/z8)?')
    assert_equal 'foo[]', build_nested_query('foo' => [nil])
    assert_equal 'foo[]=', build_nested_query('foo' => [''])
    assert_equal 'foo[]=bar', build_nested_query('foo' => ['bar'])
  end

  def test_normalize_extended_expression
    assert_equal %r{foo}, normalize_extended_expression(/foo/)
    assert_equal %r{^/extended/foo$}, normalize_extended_expression(/^\/extended\/ # comment
                                                      foo # bar
                                                      $/x)
  end
end
