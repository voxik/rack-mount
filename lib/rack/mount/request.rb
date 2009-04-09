module Rack
  module Mount
    class Request
      def initialize(env)
        @env = env
      end

      def method
        @method ||= @env[Const::REQUEST_METHOD] || Const::GET
      end

      def path
        @path ||= @env[Const::PATH_INFO] || Const::SLASH
      end

      def path_keys_at(index)
        path_keys[index]
      end

      def path_keys
        @path_keys ||= begin
          keys = path.split(%r{/|\.|\?})
          keys.shift
          keys
        end
      end
    end
  end
end
