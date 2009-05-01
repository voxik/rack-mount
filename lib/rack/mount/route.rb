module Rack
  module Mount
    class Route #:nodoc:
      # TODO: Support any method on Request object
      VALID_CONDITIONS = [:method, :path].freeze

      attr_reader :app, :conditions, :defaults, :name
      attr_reader :path, :method

      def initialize(app, conditions, defaults, name)
        @app = app
        validate_app!

        @name = name.to_sym if name
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
          @path = RegexpWithNamedGroups.compile("^#{path}$")
        end
        @path.freeze

        @conditions.freeze
      end

      # Include generation and recognition concerns
      include Generation::Route, Recognition::Route

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
  end
end
