module Rack
  module Mount
    class Route
      SKIP_RESPONSE = [404, {"Content-Type" => "text/html"}, "Not Found"]
      RACK_ROUTING_ARGS = "rack.routing_args".freeze

      HTTP_REQUEST_METHOD = "REQUEST_METHOD".freeze
      HTTP_PATH_INFO      = "PATH_INFO".freeze

      HTTP_GET    = "GET".freeze
      HTTP_HEAD   = "HEAD".freeze
      HTTP_POST   = "POST".freeze
      HTTP_PUT    = "PUT".freeze
      HTTP_DELETE = "DELETE".freeze

      HTTP_METHODS = [HTTP_GET, HTTP_HEAD, HTTP_POST, HTTP_PUT, HTTP_DELETE].freeze

      attr_reader :name, :params, :defaults, :path, :method

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

        @path = options.delete(:path).freeze
        @requirements = options.delete(:requirements).freeze
        @defaults = (options.delete(:defaults) || {}).freeze

        recognizer = @path.is_a?(Regexp) ?
          RegexpWithNamedGroups.new(@path, @requirements) :
          Utils.convert_segment_string_to_regexp(@path, @requirements)

        @recognizer = recognizer.to_regexp
        @segment_keys = Utils.extract_static_segments(@recognizer).freeze

        @params = @recognizer.names.compact.map { |n| n.to_sym }.freeze
        @indexed_params = {}
        @recognizer.named_captures.each { |k, v|
          @indexed_params[k.to_sym] = v.last - 1
        }
        @indexed_params.freeze

        @recognizer.freeze
      end

      def url_for(params = {})
        path = "/#{@path}"
        @params.each do |param|
          path.sub!(":#{param}", params[param])
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
        method = env[HTTP_REQUEST_METHOD]
        path = env[HTTP_PATH_INFO]

        if (@method.nil? || method == @method) && path =~ @recognizer
          routing_args, param_matches = {}, $~.captures
          @indexed_params.each { |k, i|
            if v = param_matches[i]
              routing_args[k] = v
            end
          }
          env[RACK_ROUTING_ARGS] = routing_args.merge!(@defaults)
          @app.call(env)
        else
          SKIP_RESPONSE
        end
      end
    end
  end
end
