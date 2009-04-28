module Rack
  module Mount
    module Recognition
      module RouteSet
        DEFAULT_KEYS = [:method, [:path_keys_at, 0].freeze].freeze
        DEFAULT_CATCH_STATUS = 404

        def initialize(options = {})
          @catch = options.delete(:catch) || DEFAULT_CATCH_STATUS
          @throw = Const::NOT_FOUND_RESPONSE.dup
          @throw[0] = @catch
          @throw.freeze

          @recognition_keys = options.delete(:keys) || DEFAULT_KEYS
          @recognition_keys.freeze

          @recognition_graph = NestedSet.new
          super
        end

        def add_route(*args)
          route = super
          route.throw = @throw

          keys = @recognition_keys.map { |key| route.send(*key) }
          @recognition_graph[*keys] = route

          route
        end

        def call(env)
          raise 'route set not finalized' unless frozen?

          req = Request.new(env)
          keys = @recognition_keys.map { |key| req.send(*key) }
          @recognition_graph[*keys].each do |route|
            result = route.call(env)
            return result unless result[0] == @catch
          end
          @throw
        end

        def freeze
          @recognition_graph.freeze
          super
        end

        def height #:nodoc:
          @recognition_graph.height
        end
      end
    end
  end
end
