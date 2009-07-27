module Rack::Mount
  module Recognition #:nodoc:
    autoload :CodeGeneration, 'rack/mount/recognition/code_generation'
    autoload :Condition, 'rack/mount/recognition/condition'
    autoload :Route, 'rack/mount/recognition/route'
    autoload :RouteSet, 'rack/mount/recognition/route_set'
  end
end
