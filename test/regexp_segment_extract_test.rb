require 'test_helper'

class RegexpSegmentExtractTest < Test::Unit::TestCase
  include Rack::Mount::Route::Utils

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

  if RUBY_VERSION >= '1.9'
    def test_regexp_with_named_regexp_groups
      re = eval('%r{/(?<controller>[a-z0-9]+)/(?<action>[a-z0-9]+)/(?<id>[0-9]+)}')
      assert_equal [nil, nil, nil], extract_static_segments(re)
    end
  end
end
