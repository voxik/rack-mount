module RecognitionTests
  require 'functional/recognition/captures'
  include Captures

  require 'functional/recognition/nesting'
  include Nesting

  require 'functional/recognition/optional_captures'
  include OptionalCaptures

  require 'functional/recognition/static_conditions'
  include StaticConditions
end
