require 'test_helper'

class BaseClassTest < Test::Unit::TestCase
  Calls = []

  module Bar
    def initialize
      BaseClassTest::Calls << "Bar#initialize"
      super
    end

    def call
      BaseClassTest::Calls << "Bar#call"
      super
    end
  end

  class Foo < Rack::Mount::BaseClass
    include Bar

    def initialize
      BaseClassTest::Calls << "Foo#initialize"
    end

    def call
      BaseClassTest::Calls << "Foo#call"
    end
  end

  def test_module_is_included_on_top_of_base_methods
    foo = Foo.new
    assert_equal ['Bar#initialize', 'Foo#initialize'], BaseClassTest::Calls

    BaseClassTest::Calls.clear

    foo.call
    assert_equal ['Bar#call', 'Foo#call'], BaseClassTest::Calls
  end
end
