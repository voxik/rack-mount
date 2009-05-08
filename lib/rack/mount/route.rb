module Rack
  module Mount
    # Route is an internal class used to wrap a single route attributes.
    #
    # Plugins should not depend on any method on this class or instantiate
    # new Route objects. Instead use the factory method, RouteSet#add_route
    # to create new routes and add them to the set.
    class Route
      extend Mixover

      # Include generation and recognition concerns
      include Generation::Route, Recognition::Route

      VALID_CONDITIONS = begin
        conditions = Rack::Request.instance_methods(false)
        conditions.map! { |m| m.to_sym }

        # FIXME: Hack to make sure path is at the end of the array
        conditions.delete(:path)
        conditions << :path

        conditions.freeze
      end

      # Valid rack application to call if conditions are met
      attr_reader :app

      # A hash of conditions to match against. Conditions may be expressed
      # as strings or regexps to match against. Currently, <tt>:method</tt>
      # and <tt>:path</tt> are the only valid conditions.
      attr_reader :conditions

      # A hash of values that always gets merged into the parameters hash
      attr_reader :defaults

      # Symbol identifier for the route used with named route generations
      attr_reader :name

      def initialize(app, conditions, defaults, name)
        @app = app
        validate_app!

        @name = name.to_sym if name
        @defaults = (defaults || {}).freeze

        @conditions = conditions
        validate_conditions!

        VALID_CONDITIONS.each do |method|
          if pattern = @conditions.delete(method)
            @conditions[method] = Condition.new(method, pattern)
          end
        end

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
  end
end
