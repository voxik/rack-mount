module Rack
  module Mount
    class RouteSet
      def self.without_optimizations
        @included_modules ||= []
        @included_modules.delete(Recognition::Optimizations)
        yield
      ensure
        @included_modules.push(Recognition::Optimizations)
      end
    end
  end
end
