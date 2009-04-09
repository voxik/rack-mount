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

    def routing_args
      @env[Rack::Mount::Const::RACK_ROUTING_ARGS]
    end

    def get(path, options = {})
      process(:get, path, options)
    end

    def post(path, options = {})
      process(:post, path, options)
    end

    def put(path, options = {})
      process(:put, path, options)
    end

    def delete(path, options = {})
      process(:delete, path, options)
    end

    def process(method, path, options = {})
      @method = method
      @path   = path

      @response = @app.call({
        Rack::Mount::Const::REQUEST_METHOD => method.to_s.upcase,
        Rack::Mount::Const::PATH_INFO => path
      }.merge(options))

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
