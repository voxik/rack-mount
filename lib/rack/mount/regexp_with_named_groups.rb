module Rack
  module Mount
    class RegexpWithNamedGroups < Regexp
      def initialize(regexp, names = nil)
        super(regexp)

        if names.is_a?(Hash)
          @names = names.sort { |a, b|
            a[1].to_int <=> b[1].to_int
          }.transpose[0].map { |n| n.to_s }
        elsif names.is_a?(Array)
          @names = names.map { |n| n.to_s }
        end
      end

      def to_regexp
        self
      end

      def names
        @names || super
      rescue NoMethodError
        []
      end
    end
  end
end
