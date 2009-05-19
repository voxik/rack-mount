module Rack
  module Mount
    module Recognition
      module RouteSet
        DEFAULT_CATCH_STATUS = 404

        # Adds recognition related concerns to RouteSet.new.
        #
        # Addition options include:
        #
        # <tt>:catch</tt>:: A "magic" status code that signals a non-match.
        #                   Defaults to 404.
        def initialize(options = {})
          @catch = options.delete(:catch) || DEFAULT_CATCH_STATUS
          @throw = Const::NOT_FOUND_RESPONSE.dup
          @throw[0] = @catch
          @throw.freeze

          @parameters_key = options.delete(:parameters_key) || Const::RACK_ROUTING_ARGS
          @parameters_key.freeze

          super
        end

        # Adds recognition aspects to RouteSet#add_route.
        def add_route(*args)
          route = super
          route.throw = @throw
          route.parameters_key = @parameters_key
          route
        end

        # Rack compatible recognition and dispatching method. Routes are
        # tried until one returns a non-catch status code. If no routes
        # match, the catch status code is returned.
        #
        # This method can only be invoked after the RouteSet has been
        # finalized.
        def call(env)
          raise 'route set not finalized' unless frozen?

          env[Const::PATH_INFO] = Utils.normalize_path(env[Const::PATH_INFO])

          cache = {}
          req = @request_class.new(env)
          keys = @recognition_keys.map { |key|
            if key.is_a?(Array)
              # TODO: Don't explict check for :path condition
              PathCondition.split(cache, req, key.first, key.last)
            else
              req.send(key)
            end
          }
          @recognition_graph[*keys].each do |route|
            result = route.call(req)
            return result unless result[0] == @catch
          end
          @throw
        end

        # Adds the recognition aspect to RouteSet#freeze. Recognition keys
        # are determined and an optimized recognition graph is constructed.
        def freeze
          recognition_keys.freeze
          recognition_graph.freeze

          super
        end

        def valid_conditions #:nodoc:
          @valid_conditions ||= begin
            conditions = @request_class.instance_methods(false)
            conditions.map! { |m| m.to_sym }
            conditions.freeze
          end
        end

        def height #:nodoc:
          @recognition_graph.height
        end

        private
          def recognition_graph
            @recognition_graph ||= begin
              build_nested_route_set(recognition_keys) { |r, k| r.keys[k] }
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
