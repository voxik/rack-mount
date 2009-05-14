require 'test_helper'

class ConditionTest < Test::Unit::TestCase
  Condition = Rack::Mount::Condition

  def test_condition_with_string_pattern
    condition = Condition.new(:request_method, 'GET')
    assert_equal %r{^GET$}, condition.to_regexp
    assert_equal({ :request_method => 'GET' }, condition.keys)
  end

  def test_condition_with_string_pattern_should_escape_pattern
    condition = Condition.new(:request_method, '37s.backpackit.com')
    assert_equal %r{^37s\.backpackit\.com$}, condition.to_regexp
    assert_equal({ :request_method => '37s.backpackit.com' }, condition.keys)
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
