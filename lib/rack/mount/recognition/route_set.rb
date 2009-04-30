module Rack
  module Mount
    module Recognition
      module RouteSet
        DEFAULT_CATCH_STATUS = 404

        def initialize(options = {})
          @catch = options.delete(:catch) || DEFAULT_CATCH_STATUS
          @throw = Const::NOT_FOUND_RESPONSE.dup
          @throw[0] = @catch
          @throw.freeze

          super
        end

        def add_route(*args)
          route = super
          route.throw = @throw
          route
        end

        def call(env)
          raise 'route set not finalized' unless frozen?

          req = Request.new(env)
          keys = @recognition_keys.map { |key| req.send(key) }
          @recognition_graph[*keys].each do |route|
            result = route.call(env)
            return result unless result[0] == @catch
          end
          @throw
        end

        def freeze
          recognition_keys.freeze
          recognition_graph.freeze

          super
        end

        def height #:nodoc:
          @recognition_graph.height
        end

        private
          def recognition_graph
            @recognition_graph ||= begin
              keys = recognition_keys
              graph = NestedSet.new
              @routes.each do |route|
                k = keys.map { |key| route.send(*key) }
                Utils.pop_trailing_nils!(k)
                graph[*k] = route
              end
              graph
            end
          end

          def recognition_keys
            @recognition_keys ||= begin
              keys = @routes.map { |route| route.keys }
              Utils.analysis_keys(keys)
            end
          end
      end
    end
  end
end
