module Rack
  module Mount
    module Recognition #:nodoc:
      autoload :Route, 'rack/mount/recognition/route'
      autoload :RouteSet, 'rack/mount/recognition/route_set'
      autoload :Optimizations, 'rack/mount/recognition/optimizations'
    end
  end
end
