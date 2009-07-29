require 'test_helper'

class AnalyzerTest < Test::Unit::TestCase
  def test_reports_are_the_best
    assert_report(:best)

    assert_report(:best,
      {:controller => 'people', :action => 'index'},
      {:controller => 'people', :action => 'show'},
      {:controller => 'posts', :action => 'index'}
    )
  end

  # TODO: Try to improve the analyzer so we can promote these
  # test cases to "best"
  def test_reports_are_better
    assert_report(:better,
      {:foo => 'bar'},
      {:foo => 'bar'}
    )

    assert_report(:better,
      {:foo => 'bar'},
      {:foo => 'bar'},
      {:foo => 'bar'},
      {:foo => 'bar'},
      {:foo => 'bar'}
    )

    assert_report(:better,
      {:controller => 'people'},
      {:controller => 'people', :action => 'show'},
      {:controller => 'posts', :action => 'show'}
    )
  end

  # TODO: Try to improve the analyzer so we can promote these
  # test cases to "better"
  def test_reports_are_good
    assert_report(:good, :foo => 'bar')

    assert_report(:good,
      {:method => 'GET', :path => '/people/1'},
      {:method => 'GET', :path => '/messages/1'},
      {:method => 'POST', :path => '/comments'}
    )

    assert_report(:good,
      {:method => 'GET', :path => '/people'},
      {:method => 'GET', :path => '/posts'},
      {:method => 'GET', :path => '/messages'},
      {:method => 'GET', :path => '/comments'}
    )
  end

  def test_analysis_boundaries
    assert_equal(['/', 's'], Rack::Mount::Analysis::Frequency.new(
      {:path => %r{^/people/([0-9]+)$}},
      {:path => %r{^/messages(/([0-9]+))$}},
      {:path => %r{^/comments$} }
    ).separators(:path))

    assert_equal(['e', '.'], Rack::Mount::Analysis::Frequency.new(
      {:path => %r{^/people(\.([a-z]+))?$}}
    ).separators(:path))

    assert_equal(['.'], Rack::Mount::Analysis::Frequency.new(
      {:host => %r{^([a-z+]).37signals.com$}}
    ).separators(:host))

    assert_equal(['-'], Rack::Mount::Analysis::Frequency.new(
      {:foo => %r{^foo-([a-z+])-bar$}}
    ).separators(:foo))
  end

  private
    def assert_report(quality, *keys)
      actual = Rack::Mount::Analysis::Frequency.new(*keys).report
      expected = GraphReport.new(keys)
      assert(expected.send("#{quality}_choices").include?(actual), "Analysis report yield #{actual.inspect} but:\n#{expected.message}\n")
    end
end
