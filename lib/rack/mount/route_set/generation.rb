module Rack
  module Mount
    class RouteSet
      module Generation
        def initialize(*args)
          @named_routes = {}
          @generation_graph = NestedSet.new
          super
        end

        def add_route(*args)
          route = super

          @named_routes[route.name] = route if route.name

          controller = route.defaults[:controller]
          action     = route.defaults[:action]
          @generation_graph[controller, action] = route

          route
        end

        def url_for(*args)
          params = args.pop if args.last.is_a?(Hash)
          named_route = args.shift

          if named_route
            route = @named_routes[named_route.to_sym]
          else
            controller = params[:controller]
            action     = params[:action]
            route = @generation_graph[controller, action].first
          end

          route.url_for(params)
        end

        def freeze
          @named_routes.freeze
          @generation_graph.freeze
          super
        end
      end
    end
  end
end
