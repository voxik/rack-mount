require 'rack/mount/regexp_with_named_groups'
require 'rack/mount/utils'
require 'strscan'

module Rack::Mount
  class Condition #:nodoc:
    include Generation::Condition, Recognition::Condition

    attr_reader :method, :pattern
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
    end

    def anchored?
      Utils.regexp_anchored?(@pattern)
    end

    def inspect
      to_regexp.inspect
    end
  end

  class SplitCondition < Condition #:nodoc:
    def self.apply(value, separator_pattern)
      keys = value.split(separator_pattern)
      keys.shift if keys[0] == Const::EMPTY_STRING
      keys << Const::NULL
      keys
    end
  end
end
