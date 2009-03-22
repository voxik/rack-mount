module Rack
  module Mount
    class RouteSet
      autoload :Base, 'rack/mount/route_set/base'
      autoload :Generation, 'rack/mount/route_set/generation'
      autoload :Optimizations, 'rack/mount/route_set/optimizations'
      autoload :Recognition, 'rack/mount/route_set/recognition'

      include Base
      include Generation, Recognition
      include Optimizations
    end
  end
end
