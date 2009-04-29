module Rack
  module Mount
    module Generation
      module RouteSet
        def initialize(options = {})
          @named_routes = {}
          @generation_graph = []
          super
        end

        def add_route(*args)
          route = super
          @named_routes[route.name] = route if route.name
          @generation_graph << route
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

        def freeze
          @named_routes.freeze
          generation_keys.freeze
          generation_graph.freeze

          super
        end

        private
          def generation_graph
            if @generation_graph.is_a?(Array)              
              keys = generation_keys
              graph = NestedSet.new
              @generation_graph.each do |route|
                k = keys.map { |key| route.defaults[key] }
                Utils.pop_trailing_nils!(k)
                graph[*k] = route
              end
              @generation_graph = graph
            else
              @generation_graph
            end
          end

          def generation_keys
            @generation_keys ||= begin
              keys = @generation_graph.map { |route| route.defaults }
              Utils.analysis_keys(keys)
            end
          end
      end
    end
  end
end
