module Rack
  module Mount
    class RouteSet
      module Base
        def initialize(options = {})
          if options.delete(:optimize) == true
            extend Recognition::Optimizations
          end

          @routes = []

          if block_given?
            yield self
            freeze
          end
        end

        # Builder method to add a route to the set
        #
        # <tt>app</tt>:: A valid Rack app to call if the conditions are met.
        # <tt>conditions</tt>:: A hash of conditions to match against.
        #                       Conditions may be expressed as strings or
        #                       regexps to match against.
        # <tt>defaults</tt>:: A hash of values that always gets merged in
        # <tt>name</tt>:: Symbol identifier for the route used with named 
        #                 route generations
        def add_route(app, conditions = {}, defaults = {}, name = nil)
          route = Route.new(app, conditions, defaults, name)
          @routes << route
          route
        end

        def freeze
          @routes.freeze
          super
        end

        private
          def build_nested_route_set(keys, &block)
            graph = NestedSet.new
            @routes.each do |route|
              k = keys.map { |key| block.call(route, key) }
              Utils.pop_trailing_nils!(k)
              graph[*k] = route
            end
            graph
          end
      end
      include Base

      include Generation::RouteSet, Recognition::RouteSet
    end
  end
end
