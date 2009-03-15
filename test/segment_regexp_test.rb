require 'test_helper'

class SegmentRegexpTest < Test::Unit::TestCase
  SegmentRegexp = Rack::Mount::Route::SegmentRegexp

  def test_simple_regexp
    re = SegmentRegexp.new(%r{/foo})

    assert_equal [nil, "foo", nil, nil], re.segment_keys
    assert_equal [], re.names
  end

  def test_simple_regexp
    re = SegmentRegexp.new(%r{/people/show/1})

    assert_equal [nil, "people", "show", "1"], re.segment_keys
    assert_equal [], re.names
  end

  def test_regexp_with_hash_of_requirements
    re = SegmentRegexp.new(%r{^/foo/(bar|baz)/([a-z0-9]+)}, :action => 1, :id => 2)

    assert_equal [nil, "foo", nil, nil], re.segment_keys
    assert_equal ['action', 'id'], re.names
  end

  def test_regexp_with_array_of_symbol_requirements
    re = SegmentRegexp.new(%r{^/foo/(bar|baz)/([a-z0-9]+)}, [:action, :id])

    assert_equal [nil, "foo", nil, nil], re.segment_keys
    assert_equal ['action', 'id'], re.names
  end

  def test_regexp_with_array_of_string_requirements
    re = SegmentRegexp.new(%r{^/foo/(bar|baz)/([a-z0-9]+)}, ['action', 'id'])

    assert_equal [nil, "foo", nil, nil], re.segment_keys
    assert_equal ['action', 'id'], re.names
  end

  if RUBY_VERSION >= '1.9'
    def test_regexp_with_named_regexp_groups
      re = eval('%r{/(?<controller>[a-z0-9]+)/(?<action>[a-z0-9]+)/(?<id>[0-9]+)}')
      re = SegmentRegexp.new(re)

      assert_equal [nil, nil, nil, nil], re.segment_keys
      assert_equal ['controller', 'action', 'id'], re.names
    end
  end
end
