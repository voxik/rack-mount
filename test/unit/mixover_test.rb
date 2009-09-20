require 'abstract_unit'

class MixoverTest < Test::Unit::TestCase
  Calls = []

  module Bar
    def initialize
      MixoverTest::Calls << "Bar#initialize"
      super
    end

    def call
      MixoverTest::Calls << "Bar#call"
      super
    end
  end

  class Foo
    extend Rack::Mount::Mixover
    include Bar

    def initialize
      MixoverTest::Calls << "Foo#initialize"
    end

    def call
      MixoverTest::Calls << "Foo#call"
    end
  end

  def test_module_is_included_on_top_of_base_methods
    foo = Foo.new
    assert_equal ['Bar#initialize', 'Foo#initialize'], MixoverTest::Calls

    MixoverTest::Calls.clear

    foo.call
    assert_equal ['Bar#call', 'Foo#call'], MixoverTest::Calls
  end
end
