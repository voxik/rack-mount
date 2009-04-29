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

          @recognition_graph = []
          super
        end

        def add_route(*args)
          route = super
          route.throw = @throw
          @recognition_graph << route
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
            if @recognition_graph.is_a?(Array)              
              keys = recognition_keys
              graph = NestedSet.new
              @recognition_graph.each do |route|
                k = keys.map { |key| route.send(*key) }
                while k.length > 0 && k.last.nil?
                  k.pop
                end
                graph[*k] = route
              end
              @recognition_graph = graph
            else
              @recognition_graph
            end
          end

          def recognition_keys
            @recognition_keys ||= begin
              keys = @recognition_graph.map { |route| route.keys }
              Utils.analysis_keys(keys)
            end
          end
      end
    end
  end
end
