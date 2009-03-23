module Rack
  module Mount
    class Route
      autoload :Optimizations, 'rack/mount/route/optimizations'

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
        path = @path.dup
        @params.each do |param|
          path.sub!(":#{param}", params[param])
          path.sub!(/\(\/(.+)\)/, '/\1')
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
        method = env[Const::REQUEST_METHOD]
        path = env[Const::PATH_INFO]

        if (@method.nil? || method == @method) && path =~ @recognizer
          routing_args, param_matches = {}, $~.captures
          @indexed_params.each { |k, i|
            if v = param_matches[i]
              routing_args[k] = v
            end
          }
          env[Const::RACK_ROUTING_ARGS] = routing_args.merge!(@defaults)
          @app.call(env)
        else
          @throw
        end
      end
    end
  end
end
