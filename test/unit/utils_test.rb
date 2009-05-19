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
    assert_equal %r{^foo|bar$}, extract_static_regexp(/^foo|bar$/)
  end

  if Rack::Mount::Const::SUPPORTS_NAMED_CAPTURES
    def test_extract_named_captures
      assert_equal [/[a-z]+/, []], extract_named_captures(eval('/[a-z]+/'))
      assert_equal [/([a-z]+)/, ['foo']], extract_named_captures(eval('/(?<foo>[a-z]+)/'))
      assert_equal [/([a-z]+)([a-z]+)/, [nil, 'foo']], extract_named_captures(eval('/([a-z]+)(?<foo>[a-z]+)/'))
    end
  else
    def test_extract_named_captures
      assert_equal [/[a-z]+/, []], extract_named_captures(/[a-z]+/)
      assert_equal [/([a-z]+)/, ['foo']], extract_named_captures(/(?:<foo>[a-z]+)/)
      assert_equal [/([a-z]+)([a-z]+)/, [nil, 'foo']], extract_named_captures(/([a-z]+)(?:<foo>[a-z]+)/)
    end
  end

  if Rack::Mount::Const::SUPPORTS_NAMED_CAPTURES
    def test_parse_segmented_string
      assert_equal %r{^foo$}, parse_segmented_string('foo')
      assert_equal eval('%r{^foo/(?<bar>[^/]+)$}'), parse_segmented_string('foo/:bar', {}, ['/'])
      assert_equal eval('%r{^(?<foo>.+)\.example\.com$}'), parse_segmented_string(':foo.example.com')
      assert_equal eval('%r{^foo/(?<bar>[a-z]+)$}'), parse_segmented_string('foo/:bar', {:bar => /[a-z]+/}, ['/'])
      assert_equal eval('%r{^foo(\.(?<extension>.+))?$}'), parse_segmented_string('foo(.:extension)')
      assert_equal eval('%r{^src/(?<files>.+)$}'), parse_segmented_string('src/*files')
    end
  else
    def test_parse_segmented_string
      assert_equal %r{^foo$}, parse_segmented_string('foo')
      assert_equal %r{^foo/(?:<bar>[^/]+)$}, parse_segmented_string('foo/:bar', {}, ['/'])
      assert_equal %r{^(?:<foo>.+)\.example\.com$}, parse_segmented_string(':foo.example.com')
      assert_equal %r{^foo/(?:<bar>[a-z]+)$}, parse_segmented_string('foo/:bar', {:bar => /[a-z]+/}, ['/'])
      assert_equal %r{^foo(\.(?:<extension>.+))?$}, parse_segmented_string('foo(.:extension)')
      assert_equal %r{^src/(?:<files>.+)$}, parse_segmented_string('src/*files')
    end
  end
end
