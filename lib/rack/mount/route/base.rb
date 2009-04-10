module Rack
  module Mount
    class Route
      module Base
        attr_reader :name, :params, :defaults
        attr_reader :path, :method
        attr_writer :throw

        def initialize(app, options)
          @app = app

          unless @app.respond_to?(:call)
            raise ArgumentError, 'app must be a valid rack application' +
              ' and respond to call'
          end

          @throw = Const::NOT_FOUND_RESPONSE

          if name = options.delete(:name)
            @name = name.to_sym
          end

          method = options.delete(:method)
          @method = method.to_s.upcase if method

          @path = options.delete(:path)
          if @path.is_a?(String)
            @path = "/#{path}" unless path =~ /^\//
          end
          @path.freeze

          @requirements = (options.delete(:requirements) || {}).freeze
          @capture_names = (options.delete(:capture_names) || {}).freeze
          @defaults = (options.delete(:defaults) || {}).freeze
        end

        def to_s
          "#{method} #{path}"
        end
      end
    end
  end
end
