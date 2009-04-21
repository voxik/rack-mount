module Rack
  module Mount
    class Route
      module Base
        attr_reader :app, :conditions, :requirements, :defaults

        attr_reader :name, :params, :defaults
        attr_reader :path, :method
        attr_writer :throw

        def initialize(app, conditions, requirements, defaults, name)
          @app = app

          unless @app.respond_to?(:call)
            raise ArgumentError, 'app must be a valid rack application' +
              ' and respond to call'
          end

          @throw = Const::NOT_FOUND_RESPONSE

          if name
            @name = name.to_sym
          end

          method = conditions.delete(:method)
          @method = method.to_s.upcase if method

          path = conditions.delete(:path)
          if path.is_a?(String)
            path = "/#{path}" unless path =~ /^\//
          end

          @requirements = (requirements || {}).freeze
          @defaults = (defaults || {}).freeze

          if path.is_a?(Regexp)
            @path = RegexpWithNamedGroups.new(path, @requirements)
          else
            # TODO: Remove this and push conversion into the mapper
            @path = Utils.convert_segment_string_to_regexp(path, @requirements)
          end
          @path.freeze
        end
      end
    end
  end
end
