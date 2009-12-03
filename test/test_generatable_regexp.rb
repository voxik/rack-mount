require 'abstract_unit'

class TestGeneratableRegexp < Test::Unit::TestCase
  GeneratableRegexp = Rack::Mount::GeneratableRegexp
  DynamicSegment = GeneratableRegexp::DynamicSegment

  def test_static
    regexp = GeneratableRegexp.compile(%r{^GET$})
    assert_equal(['GET'], regexp.segments)
    assert_equal [], regexp.captures
    assert_equal [], regexp.required_captures
    assert_equal 'GET', regexp.generate
  end

  def test_unescape_static
    regexp = GeneratableRegexp.compile(%r{^37s\.backpackit\.com$})
    assert_equal [], regexp.captures
    assert_equal [], regexp.required_captures
    assert_equal(['37s.backpackit.com'], regexp.segments)
    assert_equal '37s.backpackit.com', regexp.generate
  end

  def test_without_capture_is_ungeneratable
    regexp = GeneratableRegexp.compile(%r{^GET|POST$})
    assert !regexp.generatable?

    regexp = GeneratableRegexp.compile(%r{^.*$})
    assert !regexp.generatable?
  end

  def test_slash
    regexp = GeneratableRegexp.compile(%r{^/$})
    assert_equal [], regexp.captures
    assert_equal [], regexp.required_captures
    assert_equal ['/'], regexp.segments
    assert_equal '/', regexp.generate

    regexp = GeneratableRegexp.compile(%r{^/foo/bar$})
    assert_equal ['/foo/bar'], regexp.segments
    assert_equal [], regexp.captures
    assert_equal [], regexp.required_captures
    assert_equal '/foo/bar', regexp.generate
  end

  def test_unanchored
    regexp = GeneratableRegexp.compile(%r{^/prefix})
    assert_equal [], regexp.captures
    assert_equal [], regexp.required_captures
    assert_equal ['/prefix'], regexp.segments
    assert_equal '/prefix', regexp.generate
  end

  def test_capture
    if supports_named_captures?
      regexp = GeneratableRegexp.compile(eval('%r{^/foo/(?<id>[0-9]+)$}'))
    else
      regexp = GeneratableRegexp.compile(%r{^/foo/(?:<id>[0-9]+)$})
    end
    assert_equal ['/foo/', DynamicSegment.new(:id, %r{\A[0-9]+\Z})], regexp.segments
    assert_equal [DynamicSegment.new(:id, %r{\A[0-9]+\Z})], regexp.captures
    assert_equal [DynamicSegment.new(:id, %r{\A[0-9]+\Z})], regexp.required_captures

    assert_equal '/foo/123', regexp.generate(:id => 123)
    assert_nil regexp.generate(:id => 'abc')
  end

  def test_leading_capture
    if supports_named_captures?
      regexp = GeneratableRegexp.compile(eval('%r{^/(?<foo>[a-z]+)/bar(\.(?<format>[a-z]+))?$}'))
    else
      regexp = GeneratableRegexp.compile(%r{^/(?:<foo>[a-z]+)/bar(\.(?:<format>[a-z]+))?$})
    end
    assert_equal(['/', DynamicSegment.new(:foo, %r{\A[a-z]+\Z}),
      '/bar', ['.', DynamicSegment.new(:format, %r{\A[a-z]+\Z})]], regexp.segments)
    assert_equal [DynamicSegment.new(:foo, %r{\A[a-z]+\Z}), DynamicSegment.new(:format, %r{\A[a-z]+\Z})], regexp.captures
    assert_equal [DynamicSegment.new(:foo, %r{\A[a-z]+\Z})], regexp.required_captures

    assert_equal '/foo/bar.xml', regexp.generate(:foo => 'foo', :format => 'xml')
    assert_equal '/foo/bar', regexp.generate(:foo => 'foo')
    assert_nil regexp.generate(:format => 'xml')
  end

  def test_capture_inside_requirement
    if supports_named_captures?
      regexp = GeneratableRegexp.compile(eval('%r{^/msg/get/(?<id>\d+(?:,\d+)*)$}'))
    else
      regexp = GeneratableRegexp.compile(%r{^/msg/get/(?:<id>\d+(?:,\d+)*)$})
    end
    assert_equal(['/msg/get/', DynamicSegment.new(:id, %r{\A\d+(?:,\d+)*\Z})], regexp.segments)
    assert_equal [DynamicSegment.new(:id, %r{\A\d+(?:,\d+)*\Z})], regexp.captures
    assert_equal [DynamicSegment.new(:id, %r{\A\d+(?:,\d+)*\Z})], regexp.required_captures

    assert_equal '/msg/get/123', regexp.generate(:id => 123)
    assert_nil regexp.generate(:id => 'abc')
  end

  def test_multiple_captures
    if supports_named_captures?
      regexp = GeneratableRegexp.compile(eval('%r{^/foo/(?<action>[a-z]+)/(?<id>[0-9]+)$}'))
    else
      regexp = GeneratableRegexp.compile(%r{^/foo/(?:<action>[a-z]+)/(?:<id>[0-9]+)$})
    end
    assert_equal(['/foo/',
      DynamicSegment.new(:action, %r{\A[a-z]+\Z}), '/',
      DynamicSegment.new(:id, %r{\A[0-9]+\Z})],
    regexp.segments)
    assert_equal [DynamicSegment.new(:action, %r{\A[a-z]+\Z}), DynamicSegment.new(:id, %r{\A[0-9]+\Z})], regexp.captures
    assert_equal [DynamicSegment.new(:action, %r{\A[a-z]+\Z}), DynamicSegment.new(:id, %r{\A[0-9]+\Z})], regexp.required_captures

    assert_equal '/foo/show/1', regexp.generate(:action => 'show', :id => '1')
    assert_nil regexp.generate(:action => 'show')
    assert_nil regexp.generate(:id => '1')
  end

  def test_optional_capture
    if supports_named_captures?
      regexp = GeneratableRegexp.compile(eval('%r{^/foo/bar(\.(?<format>[a-z]+))?$}'))
    else
      regexp = GeneratableRegexp.compile(%r{^/foo/bar(\.(?:<format>[a-z]+))?$})
    end
    assert_equal(['/foo/bar', ['.', DynamicSegment.new(:format, %r{\A[a-z]+\Z})]], regexp.segments)
    assert_equal [DynamicSegment.new(:format, %r{\A[a-z]+\Z})], regexp.captures
    assert_equal [], regexp.required_captures
    assert_equal({}, regexp.required_defaults)

    assert_equal '/foo/bar.xml', regexp.generate(:format => 'xml')
    assert_equal '/foo/bar', regexp.generate
  end

  def test_capture_with_default
    if supports_named_captures?
      regexp = GeneratableRegexp.compile(eval('%r{^/foo/bar\.(?<format>[a-z]+)$}'))
    else
      regexp = GeneratableRegexp.compile(%r{^/foo/bar\.(?:<format>[a-z]+)$})
    end
    regexp.defaults[:format] = 'xml'
    assert_equal(['/foo/bar.', DynamicSegment.new(:format, %r{\A[a-z]+\Z})], regexp.segments)
    assert_equal [DynamicSegment.new(:format, %r{\A[a-z]+\Z})], regexp.captures
    assert_equal [], regexp.required_captures
    assert_equal({}, regexp.required_defaults)

    assert_equal '/foo/bar.json', regexp.generate(:format => 'json')
    assert_equal '/foo/bar.xml', regexp.generate(:format => 'xml')
    assert_equal '/foo/bar.xml', regexp.generate
  end

  def test_capture_with_required_default
    regexp = GeneratableRegexp.compile(%r{^/foo$})
    regexp.defaults[:controller] = 'foo'
    regexp.defaults[:action] = 'index'

    assert_equal(['/foo'], regexp.segments)
    assert_equal [], regexp.captures
    assert_equal [], regexp.required_captures
    assert_equal({:controller => 'foo', :action => 'index'}, regexp.required_defaults)

    assert_equal nil, regexp.generate
    assert_equal '/foo', regexp.generate(:controller => 'foo', :action => 'index')
  end

  def test_multiple_optional_captures
    if supports_named_captures?
      regexp = GeneratableRegexp.compile(eval('%r{^/(?<foo>[a-z]+)(/(?<bar>[a-z]+))?(/(?<baz>[a-z]+))?$}'))
    else
      regexp = GeneratableRegexp.compile(%r{^/(?:<foo>[a-z]+)(/(?:<bar>[a-z]+))?(/(?:<baz>[a-z]+))?$})
    end
    assert_equal(['/', DynamicSegment.new(:foo, %r{\A[a-z]+\Z}),
      ['/', DynamicSegment.new(:bar, %r{\A[a-z]+\Z})],
      ['/', DynamicSegment.new(:baz, %r{\A[a-z]+\Z})]
    ], regexp.segments)
    assert_equal [DynamicSegment.new(:foo, %r{\A[a-z]+\Z}), DynamicSegment.new(:bar, %r{\A[a-z]+\Z}), DynamicSegment.new(:baz, %r{\A[a-z]+\Z})], regexp.captures
    assert_equal [DynamicSegment.new(:foo, %r{\A[a-z]+\Z})], regexp.required_captures

    assert_equal '/foo/bar/baz', regexp.generate(:foo => 'foo', :bar => 'bar', :baz => 'baz')
    assert_equal '/foo/bar', regexp.generate(:foo => 'foo', :bar => 'bar')
    assert_equal '/foo', regexp.generate(:foo => 'foo')
    assert_nil regexp.generate
  end

  def test_capture_followed_by_an_optional_capture
    if supports_named_captures?
      regexp = GeneratableRegexp.compile(eval('%r{^/people/(?<id>[0-9]+)(\.(?<format>[a-z]+))?$}'))
    else
      regexp = GeneratableRegexp.compile(%r{^/people/(?:<id>[0-9]+)(\.(?:<format>[a-z]+))?$})
    end
    assert_equal(['/people/',
      DynamicSegment.new(:id, %r{\A[0-9]+\Z}),
      ['.', DynamicSegment.new(:format, %r{\A[a-z]+\Z})]],
    regexp.segments)
    assert_equal [DynamicSegment.new(:id, %r{\A[0-9]+\Z}), DynamicSegment.new(:format, %r{\A[a-z]+\Z})], regexp.captures
    assert_equal [DynamicSegment.new(:id, %r{\A[0-9]+\Z})], regexp.required_captures

    assert_equal '/people/123.xml', regexp.generate(:id => '123', :format => 'xml')
    assert_equal '/people/123', regexp.generate(:id => '123')
    assert_nil regexp.generate
  end

  def test_period_seperator
    if supports_named_captures?
      regexp = GeneratableRegexp.compile(eval('%r{^/foo/(?<id>[0-9]+)\.(?<format>[a-z]+)$}'))
    else
      regexp = GeneratableRegexp.compile(%r{^/foo/(?:<id>[0-9]+)\.(?:<format>[a-z]+)$})
    end
    assert_equal(['/foo/',
      DynamicSegment.new(:id, %r{\A[0-9]+\Z}), '.',
      DynamicSegment.new(:format, %r{\A[a-z]+\Z})],
    regexp.segments)
    assert_equal [DynamicSegment.new(:id, %r{\A[0-9]+\Z}), DynamicSegment.new(:format, %r{\A[a-z]+\Z})], regexp.captures
    assert_equal [DynamicSegment.new(:id, %r{\A[0-9]+\Z}), DynamicSegment.new(:format, %r{\A[a-z]+\Z})], regexp.required_captures

    assert_equal '/foo/123.xml', regexp.generate(:id => '123', :format => 'xml')
    assert_nil regexp.generate(:id => '123')
  end

  def test_escaped_capture
    regexp = GeneratableRegexp.compile(%r{^/foo/\(bar$})
    assert_equal ['/foo/(bar'], regexp.segments
    assert_equal [], regexp.captures
    assert_equal [], regexp.required_captures
    assert_equal '/foo/(bar', regexp.generate
  end

  def test_seperators_inside_optional_captures
    if supports_named_captures?
      regexp = GeneratableRegexp.compile(eval('%r{^/foo(/(?<action>[a-z]+))?$}'))
    else
      regexp = GeneratableRegexp.compile(%r{^/foo(/(?:<action>[a-z]+))?$})
    end
    assert_equal ['/foo', ['/', DynamicSegment.new(:action, %r{\A[a-z]+\Z})]], regexp.segments
    assert_equal [DynamicSegment.new(:action, %r{\A[a-z]+\Z})], regexp.captures
    assert_equal [], regexp.required_captures
    assert_equal '/foo/show', regexp.generate(:action => 'show')
    assert_equal '/foo', regexp.generate
  end

  def test_optional_capture_with_slash_and_dot
    if supports_named_captures?
      regexp = GeneratableRegexp.compile(eval('%r{^/foo(\.(?<format>[a-z]+))?$}'))
    else
      regexp = GeneratableRegexp.compile(%r{^/foo(\.(?:<format>[a-z]+))?$})
    end
    assert_equal ['/foo', ['.', DynamicSegment.new(:format, %r{\A[a-z]+\Z})]], regexp.segments
    assert_equal [DynamicSegment.new(:format, %r{\A[a-z]+\Z})], regexp.captures
    assert_equal [], regexp.required_captures
    assert_equal '/foo.xml', regexp.generate(:format => 'xml')
    assert_equal '/foo', regexp.generate
  end
end
