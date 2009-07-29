module Rack::Mount
  module Generation
    # TODO: Kill this module
    module Condition #:nodoc:
      def generatable_regexp
        @generatable_regexp ||= GeneratableRegexp.compile(to_regexp).freeze
      end

      def segments
        @generatable_regexp.segments
      end

      def generate(params, merged, defaults)
        @generatable_regexp.generate(params, merged, defaults)
      end

      def freeze
        generatable_regexp
        super
      end
    end
  end
end
