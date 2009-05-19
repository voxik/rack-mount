require 'test_helper'

class UtilsTest < Test::Unit::TestCase
  include Rack::Mount::Utils

  def test_normalize_path
    assert_equal '/foo', normalize_path('/foo')
    assert_equal '/foo', normalize_path('/foo/')
    assert_equal '/foo', normalize_path('foo')
    assert_equal '/', normalize_path('')
  end

  def test_pop_trailing_nils
    assert_equal [1, 2, 3], pop_trailing_nils!([1, 2, 3])
    assert_equal [1, 2, 3], pop_trailing_nils!([1, 2, 3, nil, nil])
    assert_equal [], pop_trailing_nils!([nil])
  end

  def test_regexp_anchored
    assert_equal true, regexp_anchored?(/^foo$/)
    assert_equal false, regexp_anchored?(/foo/)
    assert_equal false, regexp_anchored?(/^foo/)
    assert_equal false, regexp_anchored?(/foo$/)
  end

  def test_extract_static_regexp
    assert_equal 'foo', extract_static_regexp(/^foo$/)
    assert_equal 'foo.bar', extract_static_regexp(/^foo\.bar$/)
    assert_equal(/^foo|bar$/, extract_static_regexp(/^foo|bar$/))
  end
end
