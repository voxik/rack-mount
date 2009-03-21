require 'rubygems'
require 'test/unit'
require 'rack/mount'
require 'fixtures'

autoload :NestedSetGraphing, 'lib/nested_set_graphing'
autoload :BasicRecognitionTests, 'basic_recognition_tests'

module Rack
  module Mount
    class NestedSet < Hash
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
      result = @app.call({
        "REQUEST_METHOD" => method.to_s.upcase,
        "PATH_INFO" => path
      }.merge(options))

      if result
        @env = YAML.load(result[2][0])
      else
        @env = nil
      end
    end
end
