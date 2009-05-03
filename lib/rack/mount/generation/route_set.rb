module Rack
  module Mount
    module Generation
      module RouteSet
        # Adds generation related concerns to RouteSet.new.
        def initialize(*args)
          @named_routes = {}
          super
        end

        # Adds generation aspects to RouteSet#add_route.
        def add_route(*args)
          route = super
          @named_routes[route.name] = route if route.name
          route
        end

        # Generates path from identifiers or significant keys.
        #
        # To generate a url by named route, pass the name in as a +Symbol+.
        #   url_for(:dashboard) # => "/dashboard"
        #
        # Additional parameters can be passed in as a hash
        #   url_for(:people, :id => "1") # => "/people/1"
        #
        # If no name route is given, it will fall back to a slower
        # generation search.
        #   url_for(:controller => "people", :action => "show", :id => "1")
        #     # => "/people/1"
        def url_for(*args)
          params = args.last.is_a?(Hash) ? args.pop : {}
          named_route = args.shift
          route = nil

          if named_route
            unless route = @named_routes[named_route.to_sym]
              raise RoutingError, "#{named_route} failed to generate from #{params.inspect}"
            end
          else
            keys = @generation_keys.map { |key|
              if k = params[key]
                k.to_s
              else
                nil
              end
            }
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

        # Adds the generation aspect to RouteSet#freeze. Generation keys
        # are determined and an optimized generation graph is constructed.
        def freeze
          @named_routes.freeze
          generation_keys.freeze
          generation_graph.freeze

          super
        end

        private
          def generation_graph
            @generation_graph ||= begin
              build_nested_route_set(generation_keys) { |r, k|
                if k = r.defaults[k]
                  k.to_s
                else
                  nil
                end
                }
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
