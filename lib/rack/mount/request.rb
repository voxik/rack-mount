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

      def first_segment
        split_segments! unless @first_segment
        @first_segment
      end

      def second_segment
        split_segments! unless @second_segment
        @second_segment
      end

      private
        def split_segments!
          _, @first_segment, @second_segment = path.split(%r{/|\.|\?})
        end
    end
  end
end
