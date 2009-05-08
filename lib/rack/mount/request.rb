module Rack
  module Mount
    class Request #:nodoc:
      def self.valid_conditions
        conditions = instance_methods(false).map { |m| m.to_sym }
        conditions.delete(:path)
        conditions << :path
        conditions.freeze
      end

      def initialize(env)
        @env = env
      end

      def scheme
        @scheme ||= @env['rack.url_scheme']
      end

      def host
        @host ||= @env['HTTP_HOST']
      end

      def method
        @method ||= @env[Const::REQUEST_METHOD] || Const::GET
      end

      def path
        @path ||= @env[Const::PATH_INFO] ?
          Utils.normalize_path(@env[Const::PATH_INFO]) :
          Const::SLASH
      end
    end
  end
end
