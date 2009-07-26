require 'test_helper'

class AnalyzerTest < Test::Unit::TestCase
  def test_empty_key_set
    assert_equal [], report
  end

  def test_single_key_has_nothing_in_common
    assert_equal [], report(:foo => 'bar')
  end

  def test_extreme_keys_are_ignored
    assert_equal [:foo], report(
      {:foo => 'bar'},
      {:foo => 'bar'},
      {:foo => 'bar'},
      {:foo => 'bar'},
      {:foo => 'bar'},
      {:foo => 'bar'},
      {:foo => 'bar'},
      {:foo => 'bar'},
      {:foo => 'bar'},
      {:bar => 'baz'}
    )
  end

  private
    def report(*keys)
      Rack::Mount::Analyzer.new(*keys).report
    end
end
