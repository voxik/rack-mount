$: << File.join(File.dirname(__FILE__), '..', 'lib')

require 'rubygems'
require 'test/unit'
require 'rack/mount'
require 'fixtures'

autoload :BasicGenerationTests, 'functional/basic_generation_tests'
autoload :BasicRecognitionTests, 'functional/basic_recognition_tests'
autoload :ControllerConstants, 'lib/controller_constants'
autoload :FrozenAssertions, 'lib/frozen_assertions'
autoload :NestedSetGraphing, 'lib/nested_set_graphing'
autoload :RequestDSL, 'lib/request_dsl'

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

class Test::Unit::TestCase
  include FrozenAssertions
end
