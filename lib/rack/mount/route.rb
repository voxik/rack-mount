module Rack
  module Mount
    class Route
      SKIP_RESPONSE = [404, {"Content-Type" => "text/html"}, "Not Found"]
      HTTP_METHODS = ["GET", "HEAD", "POST", "PUT", "DELETE"]

      attr_reader :name, :path, :method

      def initialize(app, options)
        @app = app

        unless @app.respond_to?(:call)
          raise ArgumentError, 'app must be a valid rack application' +
            ' and respond to call'
        end

        if name = options.delete(:name)
          @name = name.to_sym
        end

        method = options.delete(:method)
        @method = method.to_s.upcase if method

        @path = options.delete(:path)
        @requirements = options.delete(:requirements).freeze
        @defaults = (options.delete(:defaults) || {}).freeze

        recognizer = @path.is_a?(Regexp) ?
          RegexpWithNamedGroups.new(@path, @requirements) :
          Utils.convert_segment_string_to_regexp(@path, @requirements)

        @recognizer = recognizer.to_regexp
        @segment_keys = Utils.extract_static_segments(@recognizer)
        @params = @recognizer.names.map { |n| n.to_sym }
      end

      def url_for(options = {})
        path = "/#{@path}"
        @params.each do |param|
          path.sub!(":#{param}", options[param.to_sym])
        end
        path
      end

      def first_segment
        @segment_keys[0]
      end

      def second_segment
        @segment_keys[1]
      end

      def to_s
        "#{method} #{path}"
      end

      def call(env)
        method = env["REQUEST_METHOD"]
        path = env["PATH_INFO"]

        if (@method.nil? || method == @method) && path =~ @recognizer
          routing_args, param_matches = {}, $~.captures
          @params.each_with_index { |p, i|
            if param_matches[i]
              routing_args[p] = param_matches[i]
            end
          }
          env["rack.routing_args"] = routing_args.merge!(@defaults)
          @app.call(env)
        else
          SKIP_RESPONSE
        end
      end
    end
  end
end
