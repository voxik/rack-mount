require 'rubygems'
require 'test/unit'
require 'rack/mount'
require 'fixtures'

autoload :BasicRecognitionTests, 'basic_recognition_tests'

module Account
  extend ControllerConstants
end

Object.extend(ControllerConstants)

module TestHelper
  private
    def env
      @env
    end

    def get(path)
      process(:get, path)
    end

    def post(path)
      process(:post, path)
    end

    def put(path)
      process(:put, path)
    end

    def delete(path)
      process(:delete, path)
    end

    def process(method, path)
      result = @app.call({
        "REQUEST_METHOD" => method.to_s.upcase,
        "PATH_INFO" => path
      })

      if result
        @env = YAML.load(result[2][0])
      else
        @env = nil
      end
    end
end
