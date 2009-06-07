require 'test_helper'

class StrexpTest < Test::Unit::TestCase
  Strexp = Rack::Mount::Strexp

  def test_leaves_regexps_alone
    assert_equal %r{foo}, Strexp.compile(%r{foo})
  end

  def test_static_string
    assert_equal %r{^foo$}, Strexp.compile('foo')
  end

  def test_dynamic_segment
    if Rack::Mount::Const::SUPPORTS_NAMED_CAPTURES
      assert_equal eval('%r{^(?<foo>.+)\.example\.com$}'), Strexp.compile(':foo.example.com')
    else
      assert_equal %r{^(?:<foo>.+)\.example\.com$}, Strexp.compile(':foo.example.com')
    end
  end

  def test_dynamic_segment_with_leading_underscore
    if Rack::Mount::Const::SUPPORTS_NAMED_CAPTURES
      assert_equal eval('%r{^(?<_foo>.+)\.example\.com$}'), Strexp.compile(':_foo.example.com')
    else
      assert_equal %r{^(?:<_foo>.+)\.example\.com$}, Strexp.compile(':_foo.example.com')
    end
  end

  def test_skips_invalid_group_names
    assert_equal %r{^:123\.example\.com$}, Strexp.compile(':123.example.com')
    assert_equal %r{^:\$\.example\.com$}, Strexp.compile(':$.example.com')
  end

  def test_escaped_dynamic_segment
    assert_equal %r{^:foo\.example\.com$}, Strexp.compile('\:foo.example.com')
  end

  def test_dynamic_segment_with_separators
    if Rack::Mount::Const::SUPPORTS_NAMED_CAPTURES
      assert_equal eval('%r{^foo/(?<bar>[^/]+)$}'), Strexp.compile('foo/:bar', {}, ['/'])
    else
      assert_equal %r{^foo/(?:<bar>[^/]+)$}, Strexp.compile('foo/:bar', {}, ['/'])
    end
  end

  def test_dynamic_segment_with_requirements
    if Rack::Mount::Const::SUPPORTS_NAMED_CAPTURES
      assert_equal eval('%r{^foo/(?<bar>[a-z]+)$}'), Strexp.compile('foo/:bar', {:bar => /[a-z]+/}, ['/'])
    else
      assert_equal %r{^foo/(?:<bar>[a-z]+)$}, Strexp.compile('foo/:bar', {:bar => /[a-z]+/}, ['/'])
    end
  end

  def test_dynamic_segment_inside_optional_segment
    if Rack::Mount::Const::SUPPORTS_NAMED_CAPTURES
      assert_equal eval('%r{^foo(\.(?<extension>.+))?$}'), Strexp.compile('foo(.:extension)')
    else
      assert_equal %r{^foo(\.(?:<extension>.+))?$}, Strexp.compile('foo(.:extension)')
    end
  end

  def test_glob_segment
    if Rack::Mount::Const::SUPPORTS_NAMED_CAPTURES
      assert_equal eval('%r{^src/(?<files>.+)$}'), Strexp.compile('src/*files')
    else
      assert_equal %r{^src/(?:<files>.+)$}, Strexp.compile('src/*files')
    end
  end

  def test_escaped_glob_segment
    assert_equal %r{^src/\*files$}, Strexp.compile('src/\*files')
  end

  def test_optional_segment
    assert_equal %r{^/foo(/bar)?$}, Strexp.compile('/foo(/bar)')
  end

  def test_consecutive_optional_segments
    assert_equal %r{^/foo(/bar)?(/baz)?$}, Strexp.compile('/foo(/bar)(/baz)')
  end

  def test_multiple_optional_segments
    assert_equal %r{^(/foo)?(/bar)?(/baz)?$}, Strexp.compile('(/foo)(/bar)(/baz)')
  end

  # Pending
  # def test_escapes_optional_segment_parenthesis
  #   assert_equal %r{^/foo\(/bar\)$}, Strexp.compile('/foo\(/bar\)')
  # end

  # Pending
  # def test_escapes_one_optional_segment_parenthesis
  #   assert_equal %r{^/foo\((/bar)?$}, Strexp.compile('/foo\((/bar)')
  # end

  # Pending
  # def test_raises_argument_error_if_optional_segment_parenthesises_are_unblanced
  #   assert_raise(ArgumentError) { Strexp.compile('/foo((/bar)') }
  #   assert_raise(ArgumentError) { Strexp.compile('/foo(/bar))') }
  # end
end
