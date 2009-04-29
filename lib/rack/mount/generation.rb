module Rack
  module Mount
    module Generation #:nodoc:
      autoload :Route, 'rack/mount/generation/route'
      autoload :RouteSet, 'rack/mount/generation/route_set'
    end
  end
end
