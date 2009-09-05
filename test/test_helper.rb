require 'rubygems'
require 'test/unit'
require 'rack/mount'
require 'fixtures'

require 'lib/permutation'
require 'lib/to_proc'

autoload :ControllerConstants, 'lib/controller_constants'
autoload :GraphReport, 'lib/graph_report'
autoload :RequestDSL, 'lib/request_dsl'

autoload :GenerationTests, 'functional/generation_tests'
autoload :RecognitionTests, 'functional/recognition_tests'

module Account
  extend ControllerConstants
end

Object.extend(ControllerConstants)
