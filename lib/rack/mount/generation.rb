module Rack
  module Mount
    module Generation
      autoload :Optimizations, 'rack/mount/generation/optimizations'
      autoload :Route, 'rack/mount/generation/route'
      autoload :RouteSet, 'rack/mount/generation/route_set'
    end
  end
end
