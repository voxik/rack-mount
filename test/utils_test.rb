require 'test_helper'

class SegmentStringTest < Test::Unit::TestCase
  include Rack::Mount::Utils

  def test_simple_string
    re = convert_segment_string_to_regexp("/foo")
    assert_equal %r{^/foo$}, re.to_regexp
    assert_equal [], re.names
  end

  def test_another_simple_string
    re = convert_segment_string_to_regexp("/people/show/1")
    assert_equal %r{^/people/show/1$}, re.to_regexp
    assert_equal [], re.names
  end

  def test_dynamic_segments
    re = convert_segment_string_to_regexp("/foo/:action/:id")
    assert_equal %r{^/foo/([^/.?]+)/([^/.?]+)$}, re.to_regexp
    assert_equal ['action', 'id'], re.names
  end

  def test_requirements
    re = convert_segment_string_to_regexp("/foo/:action/:id", :action => /bar|baz/, :id => /[a-z0-9]+/)
    assert_equal %r{^/foo/((?-mix:bar|baz))/((?-mix:[a-z0-9]+))$}, re.to_regexp
    assert_equal ['action', 'id'], re.names
  end

  def test_period_separator
    re = convert_segment_string_to_regexp("/foo/:id.:format")
    assert_equal %r{^/foo/([^/.?]+)\.([^/.?]+)$}, re.to_regexp
    assert_equal ['id', 'format'], re.names
  end

  def test_optional_segment
    re = convert_segment_string_to_regexp("/people(.:format)")
    assert_equal %r{^/people\.?([^/.?]+)?$}, re.to_regexp
    assert_equal ['format'], re.names
  end

  def test_dynamic_and_optional_segment
    re = convert_segment_string_to_regexp("/people/:id(.:format)")
    assert_equal %r{^/people/([^/.?]+)\.?([^/.?]+)?$}, re.to_regexp
    assert_equal ['id', 'format'], re.names
  end

  def test_glob
    re = convert_segment_string_to_regexp("/files/*files")
    assert_equal %r{^/files/(.*)$}, re.to_regexp
    assert_equal ['files'], re.names
  end
end

class RegexpSegmentExtractTest < Test::Unit::TestCase
  include Rack::Mount::Utils

  def test_simple_regexp
    re = %r{^/foo$}
    assert_equal ["foo"], extract_static_segments(re)
  end

  def test_another_simple_regexp
    re = %r{^/people/show/1$}
    assert_equal ["people", "show", "1"], extract_static_segments(re)
  end

  def test_regexp_with_hash_of_requirements
    re = %r{^/foo/(bar|baz)/([a-z0-9]+)}
    assert_equal ["foo"], extract_static_segments(re)
  end

  def test_regexp_with_period_separator
    re = %r{^/foo\.([a-z]+)$}
    assert_equal ["foo"], extract_static_segments(re)
  end

  if RUBY_VERSION >= '1.9'
    def test_regexp_with_named_regexp_groups
      re = eval('%r{/(?<controller>[a-z0-9]+)/(?<action>[a-z0-9]+)/(?<id>[0-9]+)}')
      assert_equal [], extract_static_segments(re)
    end
  end
end
