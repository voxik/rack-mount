require 'test_helper'

class GeneratableRegexpTest < Test::Unit::TestCase
  GeneratableRegexp = Rack::Mount::GeneratableRegexp
  DynamicSegment = GeneratableRegexp::DynamicSegment

  def test_static
    regexp = GeneratableRegexp.compile(%r{^GET$})
    assert_equal(['GET'], regexp.segments)
  end

  def test_unescape_static
    regexp = GeneratableRegexp.compile(%r{^37s\.backpackit\.com$})
    assert_equal(['37s.backpackit.com'], regexp.segments)
  end

  def test_without_capture_is_ungeneratable
    regexp = GeneratableRegexp.compile(%r{^GET|POST$})
    assert_equal([], regexp.segments)

    regexp = GeneratableRegexp.compile(%r{^.*$})
    assert_equal([], regexp.segments)
  end

  def test_slash
    regexp = GeneratableRegexp.compile(%r{^/$})
    assert_equal(['/'], regexp.segments)

    regexp = GeneratableRegexp.compile(%r{^/foo/bar$})
    assert_equal(['/foo/bar'], regexp.segments)
  end

  def test_unanchored
    regexp = GeneratableRegexp.compile(%r{^/prefix})
    assert_equal(['/prefix'], regexp.segments)
  end

  def test_capture
    if Rack::Mount::Const::SUPPORTS_NAMED_CAPTURES
      regexp = GeneratableRegexp.compile(eval('%r{^/foo/(?<id>[0-9]+)$}'))
    else
      regexp = GeneratableRegexp.compile(%r{^/foo/(?:<id>[0-9]+)$})
    end
    assert_equal(['/foo/', DynamicSegment.new(:id, %r{[0-9]+})], regexp.segments)
  end

  def test_leading_capture
    if Rack::Mount::Const::SUPPORTS_NAMED_CAPTURES
      regexp = GeneratableRegexp.compile(eval('%r{^/(?<foo>[a-z]+)/bar(\.(?<format>[a-z]+))?$}'))
    else
      regexp = GeneratableRegexp.compile(%r{^/(?:<foo>[a-z]+)/bar(\.(?:<format>[a-z]+))?$})
    end
    assert_equal(['/', DynamicSegment.new(:foo, %r{[a-z]+}),
      '/bar', ['.', DynamicSegment.new(:format, %r{[a-z]+})]], regexp.segments)
  end

  def test_capture_inside_requirement
    if Rack::Mount::Const::SUPPORTS_NAMED_CAPTURES
      regexp = GeneratableRegexp.compile(eval('%r{^/msg/get/(?<id>\d+(?:,\d+)*)$}'))
    else
      regexp = GeneratableRegexp.compile(%r{^/msg/get/(?:<id>\d+(?:,\d+)*)$})
    end
    assert_equal(['/msg/get/', DynamicSegment.new(:id, %r{\d+(?:,\d+)*})], regexp.segments)
  end

  def test_multiple_captures
    if Rack::Mount::Const::SUPPORTS_NAMED_CAPTURES
      regexp = GeneratableRegexp.compile(eval('%r{^/foo/(?<action>[a-z]+)/(?<id>[a-z]+)$}'))
    else
      regexp = GeneratableRegexp.compile(%r{^/foo/(?:<action>[a-z]+)/(?:<id>[a-z]+)$})
    end
    assert_equal(['/foo/',
      DynamicSegment.new(:action, %r{[a-z]+}), '/',
      DynamicSegment.new(:id, %r{[a-z]+})],
    regexp.segments)
  end

  def test_optional_capture
    if Rack::Mount::Const::SUPPORTS_NAMED_CAPTURES
      regexp = GeneratableRegexp.compile(eval('%r{^/foo/bar(\.(?<format>[a-z]+))?$}'))
    else
      regexp = GeneratableRegexp.compile(%r{^/foo/bar(\.(?:<format>[a-z]+))?$})
    end
    assert_equal(['/foo/bar', ['.', DynamicSegment.new(:format, %r{[a-z]+})]], regexp.segments)
  end

  def test_multiple_optional_captures
    if Rack::Mount::Const::SUPPORTS_NAMED_CAPTURES
      regexp = GeneratableRegexp.compile(eval('%r{^/(?<foo>[a-z]+)(/(?<bar>[a-z]+))?(/(?<baz>[a-z]+))?$}'))
    else
      regexp = GeneratableRegexp.compile(%r{^/(?:<foo>[a-z]+)(/(?:<bar>[a-z]+))?(/(?:<baz>[a-z]+))?$})
    end
    assert_equal(['/', DynamicSegment.new(:foo, %r{[a-z]+}),
      ['/', DynamicSegment.new(:bar, %r{[a-z]+})],
      ['/', DynamicSegment.new(:baz, %r{[a-z]+})]
    ], regexp.segments)
  end

  def test_capture_followed_by_an_optional_capture
    if Rack::Mount::Const::SUPPORTS_NAMED_CAPTURES
      regexp = GeneratableRegexp.compile(eval('%r{^/people/(?<id>[a-z]+)(\.(?<format>[a-z]+))?$}'))
    else
      regexp = GeneratableRegexp.compile(%r{^/people/(?:<id>[a-z]+)(\.(?:<format>[a-z]+))?$})
    end
    assert_equal(['/people/',
      DynamicSegment.new(:id, %r{[a-z]+}),
      ['.', DynamicSegment.new(:format, %r{[a-z]+})]],
    regexp.segments)
  end

  def test_period_seperator
    if Rack::Mount::Const::SUPPORTS_NAMED_CAPTURES
      regexp = GeneratableRegexp.compile(eval('%r{^/foo/(?<id>[0-9]+)\.(?<format>[a-z]+)$}'))
    else
      regexp = GeneratableRegexp.compile(%r{^/foo/(?:<id>[0-9]+)\.(?:<format>[a-z]+)$})
    end
    assert_equal(['/foo/',
      DynamicSegment.new(:id, %r{[0-9]+}), '.',
      DynamicSegment.new(:format, %r{[a-z]+})],
    regexp.segments)
  end

  def test_escaped_capture
    regexp = GeneratableRegexp.compile(%r{^/foo/\(bar$})
    assert_equal(['/foo/(bar'], regexp.segments)
  end

  def test_seperators_inside_optional_captures
    if Rack::Mount::Const::SUPPORTS_NAMED_CAPTURES
      regexp = GeneratableRegexp.compile(eval('%r{^/foo(/(?<action>[a-z]+))?$}'))
    else
      regexp = GeneratableRegexp.compile(%r{^/foo(/(?:<action>[a-z]+))?$})
    end
    assert_equal(['/foo', ['/', DynamicSegment.new(:action, %r{[a-z]+})]], regexp.segments)
  end

  def test_optional_capture_with_slash_and_dot
    if Rack::Mount::Const::SUPPORTS_NAMED_CAPTURES
      regexp = GeneratableRegexp.compile(eval('%r{^/foo(\.(?<format>[a-z]+))?$}'))
    else
      regexp = GeneratableRegexp.compile(%r{^/foo(\.(?:<format>[a-z]+))?$})
    end
    assert_equal(['/foo', ['.', DynamicSegment.new(:format, %r{[a-z]+})]], regexp.segments)
  end
end
