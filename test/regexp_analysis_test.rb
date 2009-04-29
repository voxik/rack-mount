require 'test_helper'

class RegexpAnalysisTest < Test::Unit::TestCase
  include Rack::Mount::Utils
  DynamicSegment = Rack::Mount::Generation::Route::DynamicSegment

  def test_requires_match_start_of_string
    re = %r{/foo$}
    assert_equal [], extract_static_segments(re)
    assert_equal [], build_generation_segments(re)
    assert_raise(ArgumentError) { extract_regexp_parts(re) }
  end

  def test_simple_static_string
    re = convert_segment_string_to_regexp('/foo', {}, %w( / . ? ))

    assert_equal %r{^/foo$}, re
    assert_equal ['foo', '$'], extract_static_segments(re)
    assert_equal ['/foo'], build_generation_segments(re)
    assert_equal ['/foo'], extract_regexp_parts(re)
  end

  def test_root_path
    re = convert_segment_string_to_regexp('/', {}, %w( / . ? ))

    assert_equal %r{^/$}, re
    assert_equal ['$'], extract_static_segments(re)
    assert_equal ['/'], build_generation_segments(re)
    assert_equal ['/'], extract_regexp_parts(re)
  end

  def test_multisegment_static_string
    re = convert_segment_string_to_regexp('/people/show/1', {}, %w( / . ? ))

    assert_equal %r{^/people/show/1$}, re
    assert_equal ['people', 'show', '1', '$'], extract_static_segments(re)
    assert_equal ['/people/show/1'], build_generation_segments(re)
    assert_equal ['/people/show/1'], extract_regexp_parts(re)
  end

  def test_dynamic_segments
    re = convert_segment_string_to_regexp('/foo/:action/:id', {}, %w( / . ? ))

    if Rack::Mount::Const::SUPPORTS_NAMED_CAPTURES
      assert_equal eval('%r{^/foo/(?<action>[^/.?]+)/(?<id>[^/.?]+)$}'), re
    else
      assert_equal %r{^/foo/([^/.?]+)/([^/.?]+)$}, re
    end

    assert_equal ['foo'], extract_static_segments(re)
    assert_equal ['/foo/', DynamicSegment.new(:action, %r{[^/.?]+}), '/', DynamicSegment.new(:id, %r{[^/.?]+})], build_generation_segments(re)
    assert_equal [
      '/foo/', Capture.new('[^/.?]+', :name => 'action'),
      '/', Capture.new('[^/.?]+', :name => 'id')
    ], extract_regexp_parts(re)
  end

  def test_dynamic_segments_with_requirements
    re = convert_segment_string_to_regexp('/foo/:action/:id',
      { :action => /bar|baz/, :id => /[a-z0-9]+/ }, %w( / . ? ))

    if Rack::Mount::Const::SUPPORTS_NAMED_CAPTURES
      assert_equal eval('%r{^/foo/(?<action>bar|baz)/(?<id>[a-z0-9]+)$}'), re
    else
      assert_equal %r{^/foo/(bar|baz)/([a-z0-9]+)$}, re
    end

    assert_equal ['foo'], extract_static_segments(re)
    assert_equal ['/foo/', DynamicSegment.new(:action, %r{bar|baz}), '/', DynamicSegment.new(:id, %r{[a-z0-9]+})], build_generation_segments(re)
    assert_equal [
      '/foo/', Capture.new('bar|baz', :name => 'action'),
      '/', Capture.new('[a-z0-9]+', :name => 'id')
    ], extract_regexp_parts(re)
  end

  def test_optional_capture
    re = convert_segment_string_to_regexp('/people/(:id)', {}, %w( / . ? ))

    if Rack::Mount::Const::SUPPORTS_NAMED_CAPTURES
      assert_equal eval('%r{^/people/((?<id>[^/.?]+))?$}'), re
    else
      assert_equal %r{^/people/(([^/.?]+))?$}, re
    end

    assert_equal ['people'], extract_static_segments(re)
    assert_equal ['/people/', [DynamicSegment.new(:id, %r{[^/.?]+})]], build_generation_segments(re)
    assert_equal ['/people/', Capture.new(
      Capture.new('[^/.?]+', :name => 'id'),
    :optional => true)], extract_regexp_parts(re)
  end

  def test_optional_capture_within_segment
    re = convert_segment_string_to_regexp('/people(.:format)', {}, %w( / . ? ))

    if Rack::Mount::Const::SUPPORTS_NAMED_CAPTURES
      assert_equal eval("%r{^/people(\\.(?<format>[^/.?]+))?$}"), re
    else
      assert_equal %r{^/people(\.([^/.?]+))?$}, re
    end

    assert_equal ['people'], extract_static_segments(re)
    assert_equal ['/people', ['.', DynamicSegment.new(:format, %r{[^/.?]+})]], build_generation_segments(re)
    assert_equal ['/people', Capture.new('\\.',
      Capture.new('[^/.?]+', :name => 'format'),
    :optional => true)], extract_regexp_parts(re)
  end

  def test_dynamic_and_optional_segment
    re = convert_segment_string_to_regexp('/people/:id(.:format)', {}, %w( / . ? ))

    if Rack::Mount::Const::SUPPORTS_NAMED_CAPTURES
      assert_equal eval("%r{^/people/(?<id>[^/.?]+)(\\.(?<format>[^/.?]+))?$}"), re
    else
      assert_equal %r{^/people/([^/.?]+)(\.([^/.?]+))?$}, re
    end

    assert_equal ['people'], extract_static_segments(re)
    assert_equal ['/people/', DynamicSegment.new(:id, %r{[^/.?]+}), ['.', DynamicSegment.new(:format, %r{[^/.?]+})]], build_generation_segments(re)
    assert_equal ['/people/', Capture.new('[^/.?]+', :name => 'id'), ['\\.', Capture.new('[^/.?]+', :name => 'format')]], extract_regexp_parts(re)
  end

  def test_nested_optional_captures
    re = convert_segment_string_to_regexp('/:controller(/:action(/:id(.:format)))', {}, %w( / . ? ))

    if Rack::Mount::Const::SUPPORTS_NAMED_CAPTURES
      assert_equal eval("%r{^/(?<controller>[^/.?]+)(/(?<action>[^/.?]+)(/(?<id>[^/.?]+)(\\.(?<format>[^/.?]+))?)?)?$}"), re
    else
      assert_equal %r{^/([^/.?]+)(/([^/.?]+)(/([^/.?]+)(\.([^/.?]+))?)?)?$}, re
    end

    assert_equal [], extract_static_segments(re)
    assert_equal ['/', DynamicSegment.new(:controller, %r{[^/.?]+}), ['/', DynamicSegment.new(:action, %r{[^/.?]+}), ['/', DynamicSegment.new(:id, %r{[^/.?]+}), ['.', DynamicSegment.new(:format, %r{[^/.?]+})]]]], build_generation_segments(re)
    assert_equal ['/', Capture.new('[^/.?]+', :name => 'controller'),
      Capture.new('/', Capture.new('[^/.?]+', :name => 'action'),
        Capture.new('/', Capture.new('[^/.?]+', :name => 'id'),
          Capture.new('\\.', Capture.new('[^/.?]+', :name => 'format'), :optional => true),
        :optional => true),
      :optional => true)
    ], extract_regexp_parts(re)
  end

  def test_regexp_simple_requirements
    re = %r{^/foo/(bar|baz)/([a-z0-9]+)}

    assert_equal ['foo'], extract_static_segments(re)
    assert_equal [], build_generation_segments(re)
    assert_equal ['/foo/', Capture.new('bar|baz'), '/',
      Capture.new('[a-z0-9]+')], extract_regexp_parts(re)
  end

  def test_another_regexp_with_requirements
    if Rack::Mount::Const::SUPPORTS_NAMED_CAPTURES
      re = eval('%r{^/regexp/bar/(?<action>[a-z]+)/(?<id>[0-9]+)$}')
      re = Rack::Mount::RegexpWithNamedGroups.new(re)
    else
      re = Rack::Mount::RegexpWithNamedGroups.new(%r{^/regexp/bar/(?:<action>[a-z]+)/(?:<id>[0-9]+)$})
    end

    assert_equal ['regexp', 'bar'], extract_static_segments(re)
    assert_equal ['/regexp/bar/', DynamicSegment.new(:action, /[a-z]+/), '/', DynamicSegment.new(:id, /[0-9]+/)], build_generation_segments(re)
    assert_equal ['/regexp/bar/', Capture.new('[a-z]+', :name => 'action'),
      '/', Capture.new('[0-9]+', :name => 'id')], extract_regexp_parts(re)
  end

  def test_period_separator
    re = convert_segment_string_to_regexp('/foo/:id.:format', {}, %w( / . ? ))

    if Rack::Mount::Const::SUPPORTS_NAMED_CAPTURES
      assert_equal eval("%r{^/foo/(?<id>[^/.?]+)\\.(?<format>[^/.?]+)$}"), re
    else
      assert_equal %r{^/foo/([^/.?]+)\.([^/.?]+)$}, re
    end

    assert_equal ['foo'], extract_static_segments(re)
    assert_equal ['/foo/', DynamicSegment.new(:id, %r{[^/.?]+}), '.', DynamicSegment.new(:format, %r{[^/.?]+})], build_generation_segments(re)
    assert_equal ['/foo/', Capture.new('[^/.?]+', :name => 'id'),
      '\\.', Capture.new('[^/.?]+', :name => 'format')
    ], extract_regexp_parts(re)
  end

  def test_glob
    re = convert_segment_string_to_regexp('/files/*files', {}, %w( / . ? ))

    if Rack::Mount::Const::SUPPORTS_NAMED_CAPTURES
      assert_equal eval("%r{^/files/(?<files>.*)$}"), re
    else
      assert_equal %r{^/files/(.*)$}, re
    end

    assert_equal ['files'], extract_static_segments(re)
    assert_equal ['/files/', DynamicSegment.new(:files, /.*/)], build_generation_segments(re)
    assert_equal ['/files/', Capture.new('.*', :name => 'files')],
      extract_regexp_parts(re)
  end

  def test_prefix_regexp
    re = %r{^/prefix/.*$}
    assert_equal ['prefix'], extract_static_segments(re)
    assert_equal ['/prefix/.*'], build_generation_segments(re)
    assert_equal ['/prefix/.*'],
      extract_regexp_parts(re)
  end

  if Rack::Mount::Const::SUPPORTS_NAMED_CAPTURES
    def test_named_regexp_groups
      re = eval('%r{^/(?<controller>[a-z0-9]+)/(?<action>[a-z0-9]+)/(?<id>[0-9]+)$}')

      assert_equal [], extract_static_segments(re)
      assert_equal ['/', DynamicSegment.new(:controller, %r{[a-z0-9]+}), '/', DynamicSegment.new(:action, %r{[a-z0-9]+}), '/', DynamicSegment.new(:id, %r{[0-9]+})], build_generation_segments(re)
      assert_equal ['/', Capture.new('[a-z0-9]+', :name => 'controller'),
        '/', Capture.new('[a-z0-9]+', :name => 'action'),
        '/', Capture.new('[0-9]+', :name => 'id')
      ], extract_regexp_parts(re)
    end

    def test_leading_static_segment
      re = eval('/^\/ruby19\/(?<action>[a-z]+)\/(?<id>[0-9]+)$/')

      assert_equal ['ruby19'], extract_static_segments(re)
      assert_equal ['/ruby19/', DynamicSegment.new(:action, %r{[a-z]+}), '/', DynamicSegment.new(:id, %r{[0-9]+})], build_generation_segments(re)
      assert_equal ['\\/ruby19\\/', Capture.new('[a-z]+', :name => 'action'),
        '\\/', Capture.new('[0-9]+', :name => 'id')
      ], extract_regexp_parts(re)
    end
  end

  private
    def extract_static_segments(re)
      route = Rack::Mount::Route.new(EchoApp, { :path => re }, {}, nil)
      route.instance_variable_get('@path_keys')
    end

    def build_generation_segments(re)
      route = Rack::Mount::Route.new(EchoApp, { :path => re }, {}, nil)
      route.instance_variable_get('@segments')
    end
end
