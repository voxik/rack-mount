module Rack
  module Mount
    class RouteSet
      module Base
        def initialize(options = {})
          if options.delete(:optimize) == true
            extend Generation::Optimizations
          end

          if block_given?
            yield self
            freeze
          end
        end

        def add_route(app, conditions = {}, requirements = {}, defaults = {}, name = nil)
          Route.new(app, conditions, requirements, defaults, name)
        end
      end
      include Base

      include Generation::RouteSet, Recognition::RouteSet
    end
  end
end
