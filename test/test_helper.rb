$: << File.join(File.dirname(__FILE__), '..', 'lib')

require 'rubygems'
require 'test/unit'
require 'rack/mount'
require 'fixtures'

require 'lib/multimap_average'
require 'lib/permutation'
require 'lib/to_proc'

autoload :ControllerConstants, 'lib/controller_constants'
autoload :FrozenAssertions, 'lib/frozen_assertions'
autoload :GraphReport, 'lib/graph_report'
autoload :RequestDSL, 'lib/request_dsl'

autoload :GenerationTests, 'functional/generation_tests'
autoload :RecognitionTests, 'functional/recognition_tests'

module Account
  extend ControllerConstants
end

Object.extend(ControllerConstants)

class Test::Unit::TestCase
  include FrozenAssertions
end
