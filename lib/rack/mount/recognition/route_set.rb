require 'rack/mount/condition'
require 'rack/mount/utils'

module Rack
  module Mount
    module Recognition
      module RouteSet
        attr_reader :parameters_key

        # Adds recognition related concerns to RouteSet.new.
        def initialize(options = {})
          @parameters_key = options.delete(:parameters_key) || Const::RACK_ROUTING_ARGS
          @parameters_key.freeze
          @recognition_key_analyzer = Analyzer.new

          super
        end

        # Adds recognition aspects to RouteSet#add_route.
        def add_route(*args)
          route = super
          @recognition_key_analyzer << route.keys
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

          set_expectation = env[Const::EXPECT] != Const::CONTINUE
          env[Const::EXPECT] = Const::CONTINUE if set_expectation

          env[Const::PATH_INFO] = Utils.normalize_path(env[Const::PATH_INFO])

          cache = {}
          req = @request_class.new(env)
          keys = @recognition_keys.map { |key|
            if key.is_a?(Array)
              (cache[key[0]] ||= SplitCondition.apply(req.send(key[0]), key[2]))[key[1]]
            else
              req.send(key)
            end
          }
          @recognition_graph[*keys].each do |route|
            result = route.call(req)
            return result unless result[0].to_i == 417
          end
          set_expectation ? Const::NOT_FOUND_RESPONSE : Const::EXPECTATION_FAILED_RESPONSE
        ensure
          env.delete(Const::EXPECT) if set_expectation
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

        private
          def recognition_graph
            @recognition_graph ||= begin
              build_nested_route_set(recognition_keys) { |r, k| r.keys[k] }
            end
          end

          def recognition_keys
            @recognition_keys ||= begin
              report = @recognition_key_analyzer.report
              @recognition_key_analyzer = nil
              report
            end
          end
      end
    end
  end
end
