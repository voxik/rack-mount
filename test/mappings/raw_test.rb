require 'test_helper'

class RawApiTest < Test::Unit::TestCase
  include TestHelper
  include BasicRecognitionTests

  def setup
    @app = BasicSet
  end

  if RUBY_VERSION >= '1.9'
    def test_named_regexp_groups
      get "/ruby19/foo/1"
      assert env
      assert_equal("GET", env["REQUEST_METHOD"])
      assert_equal({ :action => "foo", :id => "1" }, env["rack.routing_args"])
    end
  end

  def test_ensure_routeset_needs_to_be_frozen
    set = Rack::Mount::RouteSet.new
    assert_raise(RuntimeError) { set.call({}) }

    set.freeze
    assert_nothing_raised(RuntimeError) { set.call({}) }
  end

  def test_ensure_each_route_requires_a_valid_rack_app
    set = Rack::Mount::RouteSet.new
    assert_raise(ArgumentError) { set.add_route({}) }
    assert_raise(ArgumentError) { set.add_route(:app => "invalid app") }
  end
end
