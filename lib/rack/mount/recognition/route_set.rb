module Rack
  module Mount
    module Recognition
      module RouteSet
        def self.included(base) #:nodoc:
          base.class_eval do
            alias_method :initialize_without_recognition, :initialize
            alias_method :initialize, :initialize_with_recognition

            alias_method :add_route_without_recognition, :add_route
            alias_method :add_route, :add_route_with_recognition

            alias_method :freeze_without_recognition, :freeze
            alias_method :freeze, :freeze_with_recognition
          end
        end

        DEFAULT_CATCH_STATUS = 404

        def initialize_with_recognition(options = {}, &block)
          @catch = options.delete(:catch) || DEFAULT_CATCH_STATUS
          @throw = Const::NOT_FOUND_RESPONSE.dup
          @throw[0] = @catch
          @throw.freeze

          initialize_without_recognition(options, &block)
        end

        def add_route_with_recognition(*args)
          route = add_route_without_recognition(*args)
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

        def freeze_with_recognition
          recognition_keys.freeze
          recognition_graph.freeze
          freeze_without_recognition
        end

        def height #:nodoc:
          @recognition_graph.height
        end

        private
          def recognition_graph
            @recognition_graph ||= begin
              build_nested_route_set(recognition_keys) { |r, k| r.send(*k) }
            end
          end

          def recognition_keys
            @recognition_keys ||= begin
              Utils.analysis_keys(@routes.map { |r| r.keys })
            end
          end
      end
    end
  end
end
