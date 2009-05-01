module Rack
  module Mount
    module Generation
      module RouteSet
        def self.included(base) #:nodoc:
          base.class_eval do
            alias_method :initialize_without_generation, :initialize
            alias_method :initialize, :initialize_with_generation

            alias_method :add_route_without_generation, :add_route
            alias_method :add_route, :add_route_with_generation

            alias_method :freeze_without_generation, :freeze
            alias_method :freeze, :freeze_with_generation
          end
        end

        def initialize_with_generation(*args, &block)
          @named_routes = {}
          initialize_without_generation(*args, &block)
        end

        def add_route_with_generation(*args)
          route = add_route_without_generation(*args)
          @named_routes[route.name] = route if route.name
          route
        end

        def url_for(*args)
          params = args.last.is_a?(Hash) ? args.pop : {}
          named_route = args.shift
          route = nil

          if named_route
            unless route = @named_routes[named_route.to_sym]
              raise RoutingError, "#{named_route} failed to generate from #{params.inspect}"
            end
          else
            keys = @generation_keys.map { |key| params[key] }
            @generation_graph[*keys].each do |r|
              if r.defaults.all? { |k, v| params[k] == v }
                route = r
                break
              end
            end

            unless route
              raise RoutingError, "No route matches #{params.inspect}"
            end
          end

          route.url_for(params)
        end

        def freeze_with_generation
          @named_routes.freeze
          generation_keys.freeze
          generation_graph.freeze
          freeze_without_generation
        end

        private
          def generation_graph
            @generation_graph ||= begin
              build_nested_route_set(generation_keys) { |r, k| r.defaults[k] }
            end
          end

          def generation_keys
            @generation_keys ||= begin
              Utils.analysis_keys(@routes.map { |r| r.defaults })
            end
          end
      end
    end
  end
end
