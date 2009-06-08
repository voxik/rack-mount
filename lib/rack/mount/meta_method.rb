module Rack
  module Mount
    class MetaMethod
      def initialize(sym, *args)
        @sym = sym
        @args = args
        @body = []
      end

      def <<(line)
        @body << line
      end

      def inspect
<<-RUBY_EVAL
def #{@sym}(#{@args.join(', ')})
  #{@body.join("\n  ")}
end
RUBY_EVAL
      end

      def to_str
        <<-RUBY_EVAL
          def #{@sym}(#{@args.join(', ')})
            #{@body.join('; ')}
          end
        RUBY_EVAL
      end
    end
  end
end
