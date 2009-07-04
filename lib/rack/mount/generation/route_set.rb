require 'rack/mount/utils'

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
          case args.length
          when 3
            named_route, params, recall = args
          when 2
            if args[0].is_a?(Hash) && args[1].is_a?(Hash)
              params, recall = args
            else
              named_route, params = args
            end
          when 1
            if args[0].is_a?(Hash)
              params = args[0]
            else
              named_route = args[0]
            end
          else
            raise ArgumentError
          end

          named_route ||= nil
          params ||= {}
          recall ||= {}
          merged = recall.merge(params)

          route = nil

          if named_route
            if route = @named_routes[named_route.to_sym]
              recall = route.defaults.merge(recall)
              route.generate(params, recall)
            else
              raise RoutingError, "#{named_route} failed to generate from #{params.inspect}"
            end
          else
            keys = @generation_keys.map { |key|
              if k = merged[key]
                k.to_s
              else
                nil
              end
            }
            @generation_graph[*keys].each do |r|
              if url = r.generate(params, recall)
                return url
              end
            end

            raise RoutingError, "No route matches #{params.inspect}"
          end
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
                if k = r.generation_keys[k]
                  k.to_s
                else
                  nil
                end
                }
            end
          end

          def generation_keys
            @generation_keys ||= begin
              Utils.analysis_keys(@routes.map { |r| r.generation_keys })
            end
          end
      end
    end
  end
end
