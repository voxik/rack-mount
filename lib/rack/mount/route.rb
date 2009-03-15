module Rack
  module Mount
    class Route
      autoload :SegmentRegexp, 'rack/mount/route/segment_regexp'
      autoload :SegmentString, 'rack/mount/route/segment_string'

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

        segment = @path.is_a?(Regexp) ?
          SegmentRegexp.new(@path, @requirements) :
          SegmentString.new(@path, @requirements)

        # Mark as dynamic only if the first segment is dynamic
        @segments_keys = segment.segments_keys
        @recognizer = segment.recognizer
        @params = segment.params
      end

      def url_for(options = {})
        path = "/#{@path}"
        @params.each do |param|
          path.sub!(":#{param}", options[param.to_sym])
        end
        path
      end

      def first_segment
        @segments_keys[1]
      end

      def second_segment
        @segments_keys[2]
      end

      def to_s
        "#{method} #{path}"
      end

      def call(env)
        method = env["REQUEST_METHOD"]
        path = env["PATH_INFO"]

        if (@method.nil? || method == @method) && path =~ @recognizer
          routing_args, param_matches = {}, $~.captures
          @params.each_with_index { |p,i| routing_args[p] = param_matches[i] }
          env["rack.routing_args"] = routing_args.merge!(@defaults)
          @app.call(env)
        else
          SKIP_RESPONSE
        end
      end
    end
  end
end
