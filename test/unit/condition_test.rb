require 'test_helper'

class ConditionTest < Test::Unit::TestCase
  Condition = Rack::Mount::Condition

  def test_condition_with_string_pattern
    condition = Condition.new(:request_method, 'GET')
    assert_equal %r{^GET$}, condition.to_regexp
    assert_equal({ :request_method => 'GET' }, condition.keys)
  end

  def test_condition_with_string_pattern_should_escape_pattern
    condition = Condition.new(:host, '37s.backpackit.com')
    assert_equal %r{^37s\.backpackit\.com$}, condition.to_regexp
    assert_equal({ :host => '37s.backpackit.com' }, condition.keys)
  end

  def test_condition_with_regexp_pattern
    condition = Condition.new(:request_method, /^GET|POST$/)
    assert_equal %r{^GET|POST$}, condition.to_regexp
    assert_equal({ :request_method => /^GET|POST$/ }, condition.keys)
  end

  def test_condition_with_simple_pattern
    condition = Condition.new(:request_method, /^GET$/)
    assert_equal %r{^GET$}, condition.to_regexp
    assert_equal({ :request_method => 'GET' }, condition.keys)
  end

  def test_condition_with_complex_pattern
    condition = Condition.new(:request_method, /^.*$/)
    assert_equal %r{^.*$}, condition.to_regexp
    assert_equal({ :request_method => /^.*$/ }, condition.keys)
  end
end

class SplitConditionTest < Test::Unit::TestCase
  SplitCondition = Rack::Mount::SplitCondition
  EOS = Rack::Mount::Const::NULL

  def test_condition_with_path
    condition = SplitCondition.new(:path_info, '/foo/bar', %w( / ))
    assert_equal %r{^/foo/bar$}, condition.to_regexp
    assert_equal({
      [:path_info, 0] => 'foo',
      [:path_info, 1] => 'bar',
      [:path_info, 2] => EOS
     }, condition.keys)
    assert_equal ['foo', 'bar', EOS],
      condition.split('/foo/bar')
  end

  def test_condition_with_host
    condition = SplitCondition.new(:host, '37s.backpackit.com', %w( . ))
    assert_equal %r{^37s\.backpackit\.com$}, condition.to_regexp
    assert_equal({
      [:host, 0] => '37s',
      [:host, 1] => 'backpackit',
      [:host, 2] => 'com',
      [:host, 3] => EOS
    }, condition.keys)
    assert_equal ['37s', 'backpackit', 'com', EOS],
      condition.split('37s.backpackit.com')
  end

  def test_condition_with_path_with_capture
    condition = SplitCondition.new(:path_info, %r{^/foo/(?:<id>[0-9]+)$}, %w( / ))
    assert_equal %r{^/foo/([0-9]+)$}, condition.to_regexp
    assert_equal({
      [:path_info, 0] => 'foo',
      # [:path_info, 1] => /[0-9]+/,
      # [:path_info, 2] => EOS
     }, condition.keys)
    assert_equal ['foo', '123', EOS],
      condition.split('/foo/123')
  end

  def test_condition_with_path_with_optional_capture
    condition = SplitCondition.new(:path_info, %r{^/foo/bar(\.(?:<format>[a-z]+))?$}, %w( / ))
    assert_equal %r{^/foo/bar(\.([a-z]+))?$}, condition.to_regexp
    assert_equal({
      [:path_info, 0] => 'foo'
     }, condition.keys)
    assert_equal ['foo', 'bar.xml', EOS],
      condition.split('/foo/bar.xml')
  end
end
