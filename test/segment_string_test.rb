require 'test_helper'

class SegmentStringTest < Test::Unit::TestCase
  SegmentString = Rack::Mount::Route::SegmentString

  def test_simple_string
    re = SegmentString.new("/foo")
    assert_equal %r{^/foo$}, re.to_regexp
    assert_equal [], re.names
  end

  def test_another_simple_string
    re = SegmentString.new("/people/show/1")
    assert_equal %r{^/people/show/1$}, re.to_regexp
    assert_equal [], re.names
  end

  def test_string_with_dynamic_segments
    re = SegmentString.new("/foo/:action/:id")
    assert_equal %r{^/foo/([^/.?]+)/([^/.?]+)$}, re.to_regexp
    assert_equal ['action', 'id'], re.names
  end

  def test_string_with_requirements
    re = SegmentString.new("/foo/:action/:id", :action => /bar|baz/, :id => /[a-z0-9]+/)
    assert_equal %r{^/foo/((?-mix:bar|baz))/((?-mix:[a-z0-9]+))$}, re.to_regexp
    assert_equal ['action', 'id'], re.names
  end
end
