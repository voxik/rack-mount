module Rack
  module Mount
    module Generation #:nodoc:
      autoload :Optimizations, 'rack/mount/generation/optimizations'
      autoload :Route, 'rack/mount/generation/route'
      autoload :RouteSet, 'rack/mount/generation/route_set'
    end
  end
end
