$: << File.join(File.dirname(__FILE__), '..', 'lib')

require 'rubygems'
require 'test/unit'
require 'rack/mount'
require 'fixtures'

autoload :NestedSetGraphing, 'lib/nested_set_graphing'
autoload :BasicGenerationTests, 'basic_generation_tests'
autoload :BasicRecognitionTests, 'basic_recognition_tests'

module Rack
  module Mount
    class RouteSet
      include NestedSetGraphing
    end
  end
end

module Account
  extend ControllerConstants
end

Object.extend(ControllerConstants)

module TestHelper
  private
    def env
      @env
    end

    def response
      @response
    end

    def routing_args_key
      Rack::Mount::Const::RACK_ROUTING_ARGS
    end

    def routing_args
      @env[routing_args_key]
    end

    def get(path, options = {})
      process(path, options.merge(:method => 'GET'))
    end

    def post(path, options = {})
      process(path, options.merge(:method => 'POST'))
    end

    def put(path, options = {})
      process(path, options.merge(:method => 'PUT'))
    end

    def delete(path, options = {})
      process(path, options.merge(:method => 'DELETE'))
    end

    def process(path, options = {})
      @path = path

      require 'rack/mock'
      env = Rack::MockRequest.env_for(path, options)
      @response = @app.call(env)

      if @response && @response[0] == 200
        @env = YAML.load(@response[2][0])
      else
        @env = nil
      end
    end

    def assert_success
      assert(@response)
      assert_equal(200, @response[0], "No route matches #{@path.inspect}")
    end

    def assert_not_found
      assert(@response)
      assert_equal(404, @response[0])
    end
end

class Test::Unit::TestCase
  def assert_frozen(*objs)
    if objs.length > 1
      objs.each { |e| assert_frozen(e) }
      return nil
    end

    obj = objs.pop
    case obj
    when NilClass, Symbol, Integer
      return nil
    else
      assert obj.frozen?, "#{obj.inspect} was not frozen"
    end

    case obj
    when Array
      obj.each { |e| assert_frozen(e) }
    when Hash
      obj.each { |k, v| assert_frozen(k, v) }
    end

    obj.instance_variables.each do |ivar|
      assert_frozen(obj.instance_variable_get(ivar))
    end

    nil
  end
end
