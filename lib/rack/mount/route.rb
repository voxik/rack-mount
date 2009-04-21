module Rack
  module Mount
    class Route
      module Base
        # TODO: Support any method on Request object
        VALID_CONDITIONS = [:method, :path].freeze

        attr_reader :app, :conditions, :requirements, :defaults, :name
        attr_reader :path, :method
        attr_writer :throw

        def initialize(app, conditions, requirements, defaults, name)
          @app = app
          validate_app!

          @throw = Const::NOT_FOUND_RESPONSE

          @name = name.to_sym if name
          @requirements = (requirements || {}).freeze
          @defaults = (defaults || {}).freeze

          @conditions = conditions
          validate_conditions!

          method = @conditions.delete(:method)
          @method = method.to_s.upcase if method

          path = @conditions.delete(:path)
          if path.is_a?(Regexp)
            @path = RegexpWithNamedGroups.new(path)
          elsif path.is_a?(String)
            path = "/#{path}" unless path =~ /^\//
            # TODO: Remove this and push conversion into the mapper
            @path = Utils.convert_segment_string_to_regexp(path, @requirements)
          end
          @path.freeze

          @conditions.freeze
        end

        private
          def validate_app!
            unless @app.respond_to?(:call)
              raise ArgumentError, 'app must be a valid rack application' \
                ' and respond to call'
            end
          end

          def validate_conditions!
            unless @conditions.is_a?(Hash)
              raise ArgumentError, 'conditions must be a Hash'
            end

            unless @conditions.keys.all? { |k| VALID_CONDITIONS.include?(k) }
              raise ArgumentError, 'conditions may only include ' +
                VALID_CONDITIONS.inspect
            end
          end
      end
      include Base

      include Generation::Route, Recognition::Route
    end
  end
end
