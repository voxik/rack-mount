module Rack
  module Mount
    class RouteSet
      module Recognition
        DEFAULT_KEYS = [:method, :first_segment].freeze

        def initialize(options = {})
          @recognition_keys = options.delete(:keys) || DEFAULT_KEYS
          @recognition_graph = NestedSet.new
          super
        end

        def add_route(*args)
          route = super

          keys = @recognition_keys.map { |key| route.send(key) }
          @recognition_graph[*keys] = route

          route
        end

        def call(env)
          raise "route set not finalized" unless frozen?

          req = Request.new(env)
          keys = @recognition_keys.map { |key| req.send(key) }
          @recognition_graph[*keys].each do |route|
            result = route.call(env)
            return result unless result[0] == 404
          end
          nil
        end

        def freeze
          @recognition_keys.freeze
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
