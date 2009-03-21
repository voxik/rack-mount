module Rack
  module Mount
    class RouteSet
      module Recognition
        def initialize(*args)
          @recognition_graph = NestedSet.new
          super
        end

        def add_route(*args)
          route = super

          keys = @keys.map { |key| route.send(key) }
          @recognition_graph[*keys] = route

          route
        end

        def call(env)
          raise "route set not finalized" unless frozen?

          req = Request.new(env)
          keys = @keys.map { |key| req.send(key) }
          @recognition_graph[*keys].each do |route|
            result = route.call(env)
            return result unless result[0] == 404
          end
          nil
        end

        def freeze
          @recognition_graph.freeze
          super
        end

        def deepest_node
          @recognition_graph.deepest_node
        end

        def height
          @recognition_graph.height
        end

        def to_graph
          @recognition_graph.to_graph
        end
      end
    end
  end
end
