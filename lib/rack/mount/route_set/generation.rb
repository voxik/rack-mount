module Rack
  module Mount
    class RouteSet
      module Generation
        DEFAULT_KEYS = [:controller, :action].freeze

        def initialize(options = {})
          @named_routes = {}
          @generation_keys = DEFAULT_KEYS
          @generation_graph = NestedSet.new
          super
        end

        def add_route(*args)
          route = super

          @named_routes[route.name] = route if route.name

          keys = @generation_keys.map { |key| route.defaults[key] }
          @generation_graph[*keys] = route

          route
        end

        def url_for(*args)
          params = args.pop if args.last.is_a?(Hash)
          named_route = args.shift

          if named_route
            unless route = @named_routes[named_route.to_sym]
              raise RoutingError, "#{named_route} failed to generate from #{params.inspect}"
            end
          else
            keys = @generation_keys.map { |key| params[key] }
            unless route = @generation_graph[*keys].first
              raise RoutingError, "No route matches #{params.inspect}"
            end
          end

          route.url_for(params)
        end

        def freeze
          @named_routes.freeze
          @generation_keys.freeze
          @generation_graph.freeze
          super
        end
      end
    end
  end
end
