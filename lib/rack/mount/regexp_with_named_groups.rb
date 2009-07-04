require 'rack/mount/utils'

module Rack
  module Mount
    unless Const::SUPPORTS_NAMED_CAPTURES
      class RegexpWithNamedGroups < Regexp #:nodoc:
        def self.new(regexp)
          if regexp.is_a?(RegexpWithNamedGroups)
            regexp
          else
            super
          end
        end

        attr_reader :named_captures, :names

        def initialize(regexp)
          names = nil if names && !names.any?
          regexp, @names = Utils.extract_named_captures(regexp)

          @names = nil unless @names.any?

          if @names
            @named_captures = {}
            @names.each_with_index { |n, i| @named_captures[n] = [i+1] if n }
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
end
