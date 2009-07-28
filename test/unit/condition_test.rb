require 'test_helper'

class ConditionTest < Test::Unit::TestCase
  Condition = Rack::Mount::Condition
  DynamicSegment = Rack::Mount::Generation::Condition::DynamicSegment
  EOS = Rack::Mount::Const::NULL

  def test_condition_with_string_pattern
    condition = Condition.new(:request_method, 'GET')
    assert_equal %r{\AGET\Z}, condition.to_regexp
    assert_equal(['GET'], condition.segments)
  end

  def test_condition_with_string_pattern_should_escape_pattern
    condition = Condition.new(:host, '37s.backpackit.com')
    assert_equal %r{\A37s\.backpackit\.com\Z}, condition.to_regexp
    assert_equal(['37s.backpackit.com'], condition.segments)
  end

  def test_condition_with_regexp_pattern
    condition = Condition.new(:request_method, /^GET|POST$/)
    assert_equal %r{^GET|POST$}, condition.to_regexp
    assert_equal([], condition.segments)
  end

  def test_condition_with_simple_pattern
    condition = Condition.new(:request_method, /^GET$/)
    assert_equal %r{^GET$}, condition.to_regexp
    assert_equal(['GET'], condition.segments)
  end

  def test_condition_with_complex_pattern
    condition = Condition.new(:request_method, /^.*$/)
    assert_equal %r{^.*$}, condition.to_regexp
    assert_equal([], condition.segments)
  end

  def test_condition_with_root_path
    condition = Condition.new(:path_info, '/')
    assert_equal %r{\A/\Z}, condition.to_regexp
    assert_equal(['/'], condition.segments)
  end

  def test_condition_with_path_with_slash
    condition = Condition.new(:path_info, '/foo/bar')
    assert_equal %r{\A/foo/bar\Z}, condition.to_regexp
    assert_equal(['/foo/bar'], condition.segments)
  end

  def test_condition_with_path_with_slash_and_dot
    condition = Condition.new(:path_info, '/foo/bar')
    assert_equal %r{\A/foo/bar\Z}, condition.to_regexp
    assert_equal(['/foo/bar'], condition.segments)
  end

  def test_condition_with_host
    condition = Condition.new(:host, '37s.backpackit.com')
    assert_equal %r{\A37s\.backpackit\.com\Z}, condition.to_regexp
    assert_equal(['37s.backpackit.com'], condition.segments)
  end

  def test_condition_with_unanchored_path
    condition = Condition.new(:path_info, %r{^/prefix})
    assert_equal %r{^/prefix}, condition.to_regexp
    assert_equal(['/prefix'], condition.segments)
  end

  def test_condition_with_path_with_capture
    if Rack::Mount::Const::SUPPORTS_NAMED_CAPTURES
      condition = Condition.new(:path_info, eval('%r{^/foo/(?<id>[0-9]+)$}'))
      assert_equal eval('%r{^/foo/(?<id>[0-9]+)$}'), condition.to_regexp
    else
      condition = Condition.new(:path_info, %r{^/foo/(?:<id>[0-9]+)$})
      assert_equal %r{^/foo/([0-9]+)$}, condition.to_regexp
    end
    assert_equal({:id => 0}, condition.named_captures)
    assert_equal([:id], condition.required_keys)
    assert_equal({:id => /\A[0-9]+\Z/}, condition.requirements)

    assert_equal(['/foo/', DynamicSegment.new(:id, %r{[0-9]+})], condition.segments)
  end

  def test_condition_with_leading_capture
    if Rack::Mount::Const::SUPPORTS_NAMED_CAPTURES
      condition = Condition.new(:path_info, eval('%r{^/(?<foo>[a-z]+)/bar(\.(?<format>[a-z]+))?$}'))
      assert_equal eval('%r{^/(?<foo>[a-z]+)/bar(\.(?<format>[a-z]+))?$}'), condition.to_regexp
      assert_equal({:foo => 0, :format => 1}, condition.named_captures)
    else
      condition = Condition.new(:path_info, %r{^/(?:<foo>[a-z]+)/bar(\.(?:<format>[a-z]+))?$})
      assert_equal %r{^/([a-z]+)/bar(\.([a-z]+))?$}, condition.to_regexp
      assert_equal({:foo => 0, :format => 2}, condition.named_captures)
    end
    assert_equal([:foo], condition.required_keys)
    assert_equal({:foo => /\A[a-z]+\Z/, :format => /\A[a-z]+\Z/}, condition.requirements)

    assert_equal(['/', DynamicSegment.new(:foo, %r{[a-z]+}),
      '/bar', ['.', DynamicSegment.new(:format, %r{[a-z]+})]], condition.segments)
  end

  def test_condition_with_capture_inside_requirement
    if Rack::Mount::Const::SUPPORTS_NAMED_CAPTURES
      condition = Condition.new(:path_info, eval('%r{^/msg/get/(?<id>\d+(?:,\d+)*)$}'))
      assert_equal eval('%r{^/msg/get/(?<id>\d+(?:,\d+)*)$}'), condition.to_regexp
    else
      condition = Condition.new(:path_info, %r{^/msg/get/(?:<id>\d+(?:,\d+)*)$})
      assert_equal %r{^/msg/get/(\d+(?:,\d+)*)$}, condition.to_regexp
    end
    assert_equal({:id => 0}, condition.named_captures)
    assert_equal([:id], condition.required_keys)
    assert_equal({:id => /\A\d+(?:,\d+)*\Z/}, condition.requirements)

    assert_equal(['/msg/get/', DynamicSegment.new(:id, %r{\d+(?:,\d+)*})], condition.segments)
  end

  def test_condition_with_path_with_multiple_captures
    if Rack::Mount::Const::SUPPORTS_NAMED_CAPTURES
      condition = Condition.new(:path_info, eval('%r{^/foo/(?<action>[a-z]+)/(?<id>[a-z]+)$}'))
      assert_equal eval('%r{^/foo/(?<action>[a-z]+)/(?<id>[a-z]+)$}'), condition.to_regexp
    else
      condition = Condition.new(:path_info, %r{^/foo/(?:<action>[a-z]+)/(?:<id>[a-z]+)$})
      assert_equal %r{^/foo/([a-z]+)/([a-z]+)$}, condition.to_regexp
    end
    assert_equal({:action => 0, :id => 1}, condition.named_captures)
    assert_equal([:action, :id], condition.required_keys)
    assert_equal({:action => %r{\A[a-z]+\Z}, :id => %r{\A[a-z]+\Z}}, condition.requirements)

    assert_equal(['/foo/',
      DynamicSegment.new(:action, %r{[a-z]+}), '/',
      DynamicSegment.new(:id, %r{[a-z]+})],
    condition.segments)
  end

  def test_condition_with_path_with_optional_capture
    if Rack::Mount::Const::SUPPORTS_NAMED_CAPTURES
      condition = Condition.new(:path_info, eval('%r{^/foo/bar(\.(?<format>[a-z]+))?$}'))
      assert_equal eval('%r{^/foo/bar(\.(?<format>[a-z]+))?$}'), condition.to_regexp
      assert_equal({:format => 0}, condition.named_captures)
    else
      condition = Condition.new(:path_info, %r{^/foo/bar(\.(?:<format>[a-z]+))?$})
      assert_equal %r{^/foo/bar(\.([a-z]+))?$}, condition.to_regexp
      assert_equal({:format => 1}, condition.named_captures)
    end
    assert_equal([], condition.required_keys)
    assert_equal({:format => /\A[a-z]+\Z/}, condition.requirements)

    assert_equal(['/foo/bar', ['.', DynamicSegment.new(:format, %r{[a-z]+})]], condition.segments)
  end

  def test_condition_with_path_with_multiple_optional_captures
    if Rack::Mount::Const::SUPPORTS_NAMED_CAPTURES
      condition = Condition.new(:path_info, eval('%r{^/(?<foo>[a-z]+)(/(?<bar>[a-z]+))?(/(?<baz>[a-z]+))?$}'))
      assert_equal eval('%r{^/(?<foo>[a-z]+)(/(?<bar>[a-z]+))?(/(?<baz>[a-z]+))?$}'), condition.to_regexp
      assert_equal({:foo => 0, :bar => 1, :baz => 2}, condition.named_captures)
    else
      condition = Condition.new(:path_info, %r{^/(?:<foo>[a-z]+)(/(?:<bar>[a-z]+))?(/(?:<baz>[a-z]+))?$})
      assert_equal %r{^/([a-z]+)(/([a-z]+))?(/([a-z]+))?$}, condition.to_regexp
      assert_equal({:foo => 0, :bar => 2, :baz => 4}, condition.named_captures)
    end
    assert_equal([:foo], condition.required_keys)
    assert_equal({:foo => /\A[a-z]+\Z/, :bar => /\A[a-z]+\Z/, :baz => /\A[a-z]+\Z/}, condition.requirements)

    assert_equal(['/', DynamicSegment.new(:foo, %r{[a-z]+}),
      ['/', DynamicSegment.new(:bar, %r{[a-z]+})],
      ['/', DynamicSegment.new(:baz, %r{[a-z]+})]
    ], condition.segments)
  end

  def test_condition_with_path_with_capture_followed_by_an_optional_capture
    if Rack::Mount::Const::SUPPORTS_NAMED_CAPTURES
      condition = Condition.new(:path_info, eval('%r{^/people/(?<id>[a-z]+)(\.(?<format>[a-z]+))?$}'))
      assert_equal eval('%r{^/people/(?<id>[a-z]+)(\.(?<format>[a-z]+))?$}'), condition.to_regexp
      assert_equal({:id => 0, :format => 1}, condition.named_captures)
    else
      condition = Condition.new(:path_info, %r{^/people/(?:<id>[a-z]+)(\.(?:<format>[a-z]+))?$})
      assert_equal %r{^/people/([a-z]+)(\.([a-z]+))?$}, condition.to_regexp
      assert_equal({:id => 0, :format => 2}, condition.named_captures)
    end
    assert_equal([:id], condition.required_keys)
    assert_equal({:id => /\A[a-z]+\Z/, :format => /\A[a-z]+\Z/}, condition.requirements)

    assert_equal(['/people/',
      DynamicSegment.new(:id, %r{[a-z]+}),
      ['.', DynamicSegment.new(:format, %r{[a-z]+})]],
    condition.segments)
  end

  def test_condition_with_path_with_period_seperator
    if Rack::Mount::Const::SUPPORTS_NAMED_CAPTURES
      condition = Condition.new(:path_info, eval('%r{^/foo/(?<id>[0-9]+)\.(?<format>[a-z]+)$}'))
      assert_equal eval('%r{^/foo/(?<id>[0-9]+)\.(?<format>[a-z]+)$}'), condition.to_regexp
      assert_equal({:id => 0, :format => 1}, condition.named_captures)
    else
      condition = Condition.new(:path_info, %r{^/foo/(?:<id>[0-9]+)\.(?:<format>[a-z]+)$})
      assert_equal %r{^/foo/([0-9]+)\.([a-z]+)$}, condition.to_regexp
      assert_equal({:id => 0, :format => 1}, condition.named_captures)
    end


    assert_equal(['/foo/',
      DynamicSegment.new(:id, %r{[0-9]+}), '.',
      DynamicSegment.new(:format, %r{[a-z]+})],
    condition.segments)
  end

  def test_condition_with_escaped_capture
    condition = Condition.new(:path_info, %r{^/foo/\(bar$})
    assert_equal %r{^/foo/\(bar$}, condition.to_regexp
    assert_equal({}, condition.named_captures)

    assert_equal(['/foo/(bar'], condition.segments)
  end

  def test_condition_with_path_with_seperators_inside_optional_captures
    if Rack::Mount::Const::SUPPORTS_NAMED_CAPTURES
      condition = Condition.new(:path_info, eval('%r{^/foo(/(?<action>[a-z]+))?$}'))
      assert_equal eval('%r{^/foo(/(?<action>[a-z]+))?$}'), condition.to_regexp
      assert_equal({:action => 0}, condition.named_captures)
    else
      condition = Condition.new(:path_info, %r{^/foo(/(?:<action>[a-z]+))?$})
      assert_equal %r{^/foo(/([a-z]+))?$}, condition.to_regexp
      assert_equal({:action => 1}, condition.named_captures)
    end
    assert_equal([], condition.required_keys)
    assert_equal({:action => /\A[a-z]+\Z/}, condition.requirements)

    assert_equal(['/foo', ['/', DynamicSegment.new(:action, %r{[a-z]+})]], condition.segments)
  end

  def test_condition_with_path_with_optional_capture_with_slash_and_dot
    if Rack::Mount::Const::SUPPORTS_NAMED_CAPTURES
      condition = Condition.new(:path_info, eval('%r{^/foo(\.(?<format>[a-z]+))?$}'))
      assert_equal eval('%r{^/foo(\.(?<format>[a-z]+))?$}'), condition.to_regexp
      assert_equal({:format => 0}, condition.named_captures)
    else
      condition = Condition.new(:path_info, %r{^/foo(\.(?:<format>[a-z]+))?$})
      assert_equal %r{^/foo(\.([a-z]+))?$}, condition.to_regexp
      assert_equal({:format => 1}, condition.named_captures)
    end
    assert_equal([], condition.required_keys)
    assert_equal({:format => /\A[a-z]+\Z/}, condition.requirements)

    assert_equal(['/foo', ['.', DynamicSegment.new(:format, %r{[a-z]+})]], condition.segments)
  end
end
