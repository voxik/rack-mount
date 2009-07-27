require 'test_helper'

class RegexpAnalysisTest < Test::Unit::TestCase
  DynamicSegment = Rack::Mount::Generation::Route::DynamicSegment
  EOS = Rack::Mount::Const::NULL

  def test_nested_optional_captures
    re = parse_segmented_string('/:controller(/:action(/:id(.:format)))', {}, %w( / . ? ))

    if Rack::Mount::Const::SUPPORTS_NAMED_CAPTURES
      assert_equal eval('%r{\A/(?<controller>[^/.?]+)(/(?<action>[^/.?]+)(/(?<id>[^/.?]+)(\\.(?<format>[^/.?]+))?)?)?\Z}'), re
    else
      assert_equal %r{\A/([^/.?]+)(/([^/.?]+)(/([^/.?]+)(\.([^/.?]+))?)?)?\Z}, re
    end

    assert_equal [%r{\A[^/.?]+\Z}], extract_static_segments(re)
    assert_equal ['/', DynamicSegment.new(:controller, %r{[^/.?]+}), ['/', DynamicSegment.new(:action, %r{[^/.?]+}), ['/', DynamicSegment.new(:id, %r{[^/.?]+}), ['.', DynamicSegment.new(:format, %r{[^/.?]+})]]]], build_generation_segments(re)
  end

  def test_regexp_simple_requirements
    re = %r{^/foo/(bar|baz)/([a-z0-9]+)$}

    assert_equal ['foo', %r{\Abar|baz\Z}, %r{\A[a-z0-9]+\Z}, EOS], extract_static_segments(re)
    assert_equal [], build_generation_segments(re)
  end

  def test_another_regexp_with_requirements
    if Rack::Mount::Const::SUPPORTS_NAMED_CAPTURES
      re = eval('%r{\A/regexp/bar/(?<action>[a-z]+)/(?<id>[0-9]+)\Z}')
      re = Rack::Mount::RegexpWithNamedGroups.new(re)
    else
      re = Rack::Mount::RegexpWithNamedGroups.new(%r{\A/regexp/bar/(?:<action>[a-z]+)/(?:<id>[0-9]+)\Z})
    end

    assert_equal ['regexp', 'bar', /\A[a-z]+\Z/, /\A[0-9]+\Z/, EOS], extract_static_segments(re)
    assert_equal ['/regexp/bar/', DynamicSegment.new(:action, /[a-z]+/), '/', DynamicSegment.new(:id, /[0-9]+/)], build_generation_segments(re)
  end

  def test_period_separator
    re = parse_segmented_string('/foo/:id.:format', {}, %w( / . ? ))

    if Rack::Mount::Const::SUPPORTS_NAMED_CAPTURES
      assert_equal eval('%r{\A/foo/(?<id>[^/.?]+)\\.(?<format>[^/.?]+)\Z}'), re
    else
      assert_equal %r{\A/foo/([^/.?]+)\.([^/.?]+)\Z}, re
    end

    assert_equal ['foo', %r{\A[^/.?]+\Z}, %r{\A[^/.?]+\Z}, EOS], extract_static_segments(re)
    assert_equal ['/foo/', DynamicSegment.new(:id, %r{[^/.?]+}), '.', DynamicSegment.new(:format, %r{[^/.?]+})], build_generation_segments(re)
  end

  def test_glob
    re = parse_segmented_string('/files/*files', {}, %w( / . ? ))

    if Rack::Mount::Const::SUPPORTS_NAMED_CAPTURES
      assert_equal eval('%r{\A/files/(?<files>.+)\Z}'), re
    else
      assert_equal %r{\A/files/(.+)\Z}, re
    end

    assert_equal ['files'], extract_static_segments(re)
    assert_equal ['/files/', DynamicSegment.new(:files, /.+/)], build_generation_segments(re)
  end

  def test_prefix_regexp
    re = %r{^/prefix}
    assert_equal ['prefix'], extract_static_segments(re)
    assert_equal ['/prefix'], build_generation_segments(re)
  end

  if Rack::Mount::Const::SUPPORTS_NAMED_CAPTURES
    def test_named_regexp_groups
      re = eval('%r{^/(?<controller>[a-z0-9]+)/(?<action>[a-z0-9]+)/(?<id>[0-9]+)$}')

      assert_equal [%r{\A[a-z0-9]+\Z}, %r{\A[a-z0-9]+\Z}, %r{\A[0-9]+\Z}, EOS], extract_static_segments(re)
      assert_equal ['/', DynamicSegment.new(:controller, %r{[a-z0-9]+}), '/', DynamicSegment.new(:action, %r{[a-z0-9]+}), '/', DynamicSegment.new(:id, %r{[0-9]+})], build_generation_segments(re)
    end

    def test_leading_static_segment
      re = eval('%r{^/ruby19/(?<action>[a-z]+)/(?<id>[0-9]+)$}')

      assert_equal ['ruby19', %r{\A[a-z]+\Z}, %r{\A[0-9]+\Z}, EOS], extract_static_segments(re)
      assert_equal ['/ruby19/', DynamicSegment.new(:action, %r{[a-z]+}), '/', DynamicSegment.new(:id, %r{[0-9]+})], build_generation_segments(re)
    end
  end

  private
    def parse_segmented_string(*args)
      Rack::Mount::RegexpWithNamedGroups.new(Rack::Mount::Strexp.new(*args))
    end

    def extract_static_segments(re)
      set = Rack::Mount::RouteSet.new
      route = Rack::Mount::Route.new(set, EchoApp, { :path_info => re }, {}, nil)
      route.conditions[:path_info].keys.sort { |(k1, v1), (k2, v2)| k1.to_s <=> k2.to_s }.map { |(k, v)| v }
    end

    def build_generation_segments(re)
      set = Rack::Mount::RouteSet.new
      route = Rack::Mount::Route.new(set, EchoApp, { :path_info => re }, {}, nil)
      route.instance_variable_get('@segments')[:path_info]
    end
end
