module Rack
  module Mount
    class Route
      autoload :Base, 'rack/mount/route/base'
      autoload :Generation, 'rack/mount/route/generation'
      autoload :Optimizations, 'rack/mount/route/optimizations'
      autoload :Recognition, 'rack/mount/route/recognition'

      include Base
      include Generation, Recognition
    end
  end
end
