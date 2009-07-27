require 'rack/mount/utils'

module Rack::Mount
  unless Const::SUPPORTS_NAMED_CAPTURES
    # A wrapper that adds shim named capture support to older
    # versions of Ruby.
    #
    # Because the named capture syntax causes a parse error, an
    # alternate syntax is used to indicate named captures.
    #
    # Ruby 1.9+ named capture syntax:
    #
    #   /(?<foo>[a-z]+)/
    #
    # Ruby 1.8 shim syntax:
    #
    #   /(?:<foo>[a-z]+)/
    class RegexpWithNamedGroups < Regexp
      def self.new(regexp) #:nodoc:
        if regexp.is_a?(RegexpWithNamedGroups)
          regexp
        else
          super
        end
      end

      attr_reader :named_captures, :names

      # Wraps Regexp with named capture support.
      def initialize(regexp)
        names = nil if names && !names.any?
        regexp, @names = Utils.extract_named_captures(regexp)

        @names = nil unless @names.any?

        if @names
          @named_captures = {}
          @names.each_with_index { |n, i|
            @named_captures[n] = [i+1].freeze if n
          }
        end

        (@named_captures ||= {}).freeze
        (@names ||= []).freeze

        super(regexp)
      end
    end
  else
    RegexpWithNamedGroups = Regexp
  end
end
