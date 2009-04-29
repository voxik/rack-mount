module Rack
  module Mount
    class Request #:nodoc:
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
          keys << Const::EOS_KEY
          keys
        end
      end

      10.times do |n|
        class_eval(<<-EOS, __FILE__, __LINE__)
          def path_keys_at_#{n}
            path_keys[#{n}]
          end
        EOS
      end
    end
  end
end
