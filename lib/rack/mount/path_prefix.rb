module Rack
  module Mount
    class PathPrefix #:nodoc:
      def initialize(app, path_prefix = nil)
        @app, @path_prefix = app, /^#{Regexp.escape(path_prefix)}/.freeze
      end

      def call(env)
        path_info = Const::PATH_INFO

        if env[path_info] =~ @path_prefix
          env[path_info].sub!(@path_prefix, Const::EMPTY_STRING)
          env[path_info] = Const::SLASH if env[path_info].empty?
        end

        @app.call(env)
      end
    end
  end
end
