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

          @routes = []
          super
        end

        def add_route(*args)
          route = super
          route.throw = @throw
          @routes << route
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
          @routes = nil

          super
        end

        def height #:nodoc:
          @recognition_graph.height
        end

        private
          def recognition_keys
            @recognition_keys ||= generate_keys(@routes)
          end

          def recognition_graph
            @recognition_graph ||= build_graph(@routes, recognition_keys)
          end

          def build_graph(routes, keys)
            graph = NestedSet.new
            routes.each do |route|
              k = keys.map { |key| route.send(*key) }
              while k.length > 0 && k.last.nil?
                k.pop
              end
              graph[*k] = route
            end
            graph
          end

          def generate_keys(routes)
            key_statistics = {}
            routes.each do |route|
              route.keys.each do |key, value|
                key_statistics[key] ||= 0
                key_statistics[key] += 1
              end
            end
            key_statistics = key_statistics.sort { |e1, e2| e1[1] <=> e2[1] }
            key_statistics.reverse!
            key_statistics.map! { |e| e[0] }
            key_statistics
          end
      end
    end
  end
end
