require 'abstract_unit'

class TestSplitting < Test::Unit::TestCase
  def test_expire_expires_report
    splitting = new_splitting
    splitting << {:a => "/a"}
    splitting << {:b => "/b"}
    splitting << {:c => "/c"}
    assert_equal([:a, :b, :c], splitting.report.sort_by(&:to_s))

    splitting.expire!
    splitting << {:d => "/d"}
    splitting << {:d => "/d"}
    assert_equal([:d], splitting.report)
  end

  private
    def new_splitting(*args)
      Rack::Mount::Analysis::Splitting.new(*args)
    end
end
