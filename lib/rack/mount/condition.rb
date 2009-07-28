require 'rack/mount/regexp_with_named_groups'
require 'rack/mount/utils'
require 'strscan'

module Rack::Mount
  class Condition #:nodoc:
    include Generation::Condition

    attr_reader :method, :pattern
    attr_reader :named_captures
    alias_method :to_regexp, :pattern

    def initialize(method, pattern)
      @method = method.to_sym

      @pattern = pattern
      @keys = {}

      if @pattern.is_a?(String)
        @pattern = Regexp.escape(@pattern)
        @pattern = Regexp.compile("\\A#{@pattern}\\Z")
      end

      @pattern = RegexpWithNamedGroups.new(@pattern).freeze

      @named_captures = @pattern.named_captures.inject({}) { |named_captures, (k, v)|
        named_captures[k.to_sym] = v.last - 1
        named_captures
      }.freeze
    end

    def anchored?
      Utils.regexp_anchored?(@pattern)
    end

    def inspect
      to_regexp.inspect
    end
  end
end
