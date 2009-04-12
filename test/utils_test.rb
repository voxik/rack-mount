require 'test_helper'

class RegexpSegmentExtractTest < Test::Unit::TestCase
  include Rack::Mount::Utils

  def setup
    @separators = %w( / )
  end

  def test_requires_to_match_start_of_string
    re = %r{/foo$}
    assert_equal [], extract_static_segments(re, @separators)
    assert_raise(ArgumentError) { extract_regexp_parts(re) }
  end

  def test_simple_regexp
    re = convert_segment_string_to_regexp("/foo")
    assert_equal %r{^/foo$}, re
    assert_equal [], re.names
    assert_equal({}, re.named_captures)
    assert_equal ['foo'], extract_static_segments(re, @separators)
    assert_equal ['/foo'], extract_regexp_parts(re)
  end

  def test_another_simple_regexp
    re = convert_segment_string_to_regexp("/people/show/1")
    assert_equal %r{^/people/show/1$}, re
    assert_equal [], re.names
    assert_equal({}, re.named_captures)
    assert_equal ['people', 'show', '1'], extract_static_segments(re, @separators)
    assert_equal ['/people/show/1'], extract_regexp_parts(re)
  end

  def test_dynamic_segments
    re = convert_segment_string_to_regexp("/foo/:action/:id")

    if Rack::Mount::Const::SUPPORTS_NAMED_CAPTURES
      assert_equal eval("%r{^/foo/(?<action>[^/.?]+)/(?<id>[^/.?]+)$}"), re
    else
      assert_equal %r{^/foo/([^/.?]+)/([^/.?]+)$}, re
    end
    assert_equal ['action', 'id'], re.names
    assert_equal({ 'action' => [1], 'id' => [2] }, re.named_captures)

    assert_equal ['foo'], extract_static_segments(re, @separators)
    assert_equal ['/foo/', Capture.new('[^/.?]+', :name => 'action'), '/', Capture.new('[^/.?]+', :name => 'id')], extract_regexp_parts(re)
  end

  def test_requirements
    re = convert_segment_string_to_regexp("/foo/:action/:id", :action => /bar|baz/, :id => /[a-z0-9]+/)

    if Rack::Mount::Const::SUPPORTS_NAMED_CAPTURES
      assert_equal eval("%r{^/foo/(?<action>bar|baz)/(?<id>[a-z0-9]+)$}"), re
    else
      assert_equal %r{^/foo/(bar|baz)/([a-z0-9]+)$}, re
    end
    assert_equal ['action', 'id'], re.names
    assert_equal({ 'action' => [1], 'id' => [2] }, re.named_captures)

    assert_equal ['foo'], extract_static_segments(re, @separators)
    assert_equal ['/foo/', Capture.new('bar|baz', :name => 'action'), '/', Capture.new('[a-z0-9]+', :name => 'id')], extract_regexp_parts(re)
  end

  def test_optional_capture
    re = %r{^/people/(.+)?$}
    assert_equal ['people'], extract_static_segments(re, @separators)
    assert_equal ['/people/', Capture.new('.+', :optional => true)], extract_regexp_parts(re)
  end

  def test_optional_segment
    re = convert_segment_string_to_regexp("/people(.:format)")

    if Rack::Mount::Const::SUPPORTS_NAMED_CAPTURES
      assert_equal eval("%r{^/people(\\.(?<format>[^/.?]+))?$}"), re
      assert_equal ['format'], re.names
      assert_equal({ 'format' => [1] }, re.named_captures)
    else
      assert_equal %r{^/people(\.([^/.?]+))?$}, re
      assert_equal [nil, 'format'], re.names
      assert_equal({ 'format' => [2] }, re.named_captures)
    end

    assert_equal ['people'], extract_static_segments(re, @separators)
    assert_equal ['/people', Capture.new('\\.', Capture.new('[^/.?]+', :name => 'format'), :optional => true)], extract_regexp_parts(re)
  end

  def test_dynamic_and_optional_segment
    re = convert_segment_string_to_regexp("/people/:id(.:format)")

    if Rack::Mount::Const::SUPPORTS_NAMED_CAPTURES
      assert_equal eval("%r{^/people/(?<id>[^/.?]+)(\\.(?<format>[^/.?]+))?$}"), re
      assert_equal ['id', 'format'], re.names
      assert_equal({ 'id' => [1], 'format' => [2] }, re.named_captures)
    else
      assert_equal %r{^/people/([^/.?]+)(\.([^/.?]+))?$}, re
      assert_equal ['id', nil, 'format'], re.names
      assert_equal({ 'id' => [1], 'format' => [3] }, re.named_captures)
    end

    assert_equal ['people'], extract_static_segments(re, @separators)
    assert_equal ['/people/', Capture.new('[^/.?]+', :name => 'id'), ['\\.', Capture.new('[^/.?]+', :name => 'format')]], extract_regexp_parts(re)
  end

  def test_nested_optional_segment
    re = convert_segment_string_to_regexp("/:controller(/:action(/:id(.:format)))")

    if Rack::Mount::Const::SUPPORTS_NAMED_CAPTURES
      assert_equal eval("%r{^/(?<controller>[^/.?]+)(/(?<action>[^/.?]+)(/(?<id>[^/.?]+)(\\.(?<format>[^/.?]+))?)?)?$}"), re
      assert_equal ['controller', 'action', 'id', 'format'], re.names
      assert_equal({ 'controller' => [1], 'action' => [2], 'id' => [3], 'format' => [4] }, re.named_captures)
    else
      assert_equal %r{^/([^/.?]+)(/([^/.?]+)(/([^/.?]+)(\.([^/.?]+))?)?)?$}, re
      assert_equal ['controller', nil, 'action', nil, 'id', nil, 'format'], re.names
      assert_equal({ 'controller' => [1], 'action' => [3], 'id' => [5], 'format' => [7] }, re.named_captures)
    end

    assert_equal [], extract_static_segments(re, @separators)
    assert_equal ['/', Capture.new("[^/.?]+", :name => 'controller'),
      Capture.new('/', Capture.new('[^/.?]+', :name => 'action'),
        Capture.new('/', Capture.new('[^/.?]+', :name => 'id'),
          Capture.new('\\.', Capture.new('[^/.?]+', :name => 'format'), :optional => true),
        :optional => true),
      :optional => true)
    ], extract_regexp_parts(re)
  end

  def test_regexp_with_hash_of_requirements
    re = %r{^/foo/(bar|baz)/([a-z0-9]+)}
    assert_equal ['foo'], extract_static_segments(re, @separators)
    assert_equal ['/foo/', Capture.new('bar|baz'), '/', Capture.new('[a-z0-9]+')], extract_regexp_parts(re)
  end

  def test_period_separator
    re = convert_segment_string_to_regexp("/foo/:id.:format")

    if Rack::Mount::Const::SUPPORTS_NAMED_CAPTURES
      assert_equal eval("%r{^/foo/(?<id>[^/.?]+)\\.(?<format>[^/.?]+)$}"), re
    else
      assert_equal %r{^/foo/([^/.?]+)\.([^/.?]+)$}, re
    end
    assert_equal ['id', 'format'], re.names
    assert_equal({ 'id' => [1], 'format' => [2] }, re.named_captures)

    assert_equal ['foo'], extract_static_segments(re, @separators)
    assert_equal ['/foo/', Capture.new('[^/.?]+', :name => 'id'), '\\.', Capture.new('[^/.?]+', :name => 'format')], extract_regexp_parts(re)
  end

  def test_glob
    re = convert_segment_string_to_regexp("/files/*files")

    if Rack::Mount::Const::SUPPORTS_NAMED_CAPTURES
      assert_equal eval("%r{^/files/(?<files>.*)$}"), re
    else
      assert_equal %r{^/files/(.*)$}, re
    end

    assert_equal ['files'], re.names
    assert_equal({ 'files' => [1] }, re.named_captures)

    assert_equal ['files'], extract_static_segments(re, @separators)
    assert_equal ['/files/', Capture.new('.*', :name => 'files')], extract_regexp_parts(re)
  end

  def test_regexp_with_period_separator
    re = %r{^/foo\.([a-z]+)$}
    assert_equal [], extract_static_segments(re, @separators)
    assert_equal ['/foo\\.', Capture.new('[a-z]+')], extract_regexp_parts(re)
  end

  if Rack::Mount::Const::SUPPORTS_NAMED_CAPTURES
    def test_regexp_with_named_regexp_groups
      re = eval('%r{^/(?<controller>[a-z0-9]+)/(?<action>[a-z0-9]+)/(?<id>[0-9]+)$}')
      assert_equal [], extract_static_segments(re, @separators)
      assert_equal ['/', Capture.new('[a-z0-9]+', :name => 'controller'),
        '/', Capture.new('[a-z0-9]+', :name => 'action'),
        '/', Capture.new('[0-9]+', :name => 'id')
      ], extract_regexp_parts(re)
    end

    def test_leading_static_segment
      re = eval('/^\/ruby19\/(?<action>[a-z]+)\/(?<id>[0-9]+)$/')
      assert_equal ['ruby19'], extract_static_segments(re, @separators)
      assert_equal ['\\/ruby19\\/', Capture.new('[a-z]+', :name => 'action'),
        '\\/', Capture.new('[0-9]+', :name => 'id')
      ], extract_regexp_parts(re)
    end
  end
end
