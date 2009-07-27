module Rack::Mount
  class Analyzer #:nodoc:
    def initialize(*keys)
      clear
      keys.each { |key| self << key }
    end

    def clear
      @key_frequency = {}
      @value_count = 0

      self
    end

    def <<(key)
      raise ArgumentError unless key.is_a?(Hash)

      key.each_pair do |key, value|
        @key_frequency[key] ||= 0
        @key_frequency[key] += 1
        @value_count += 1
      end

      nil
    end

    def report
      return [] if @value_count <= 1

      keys = @key_frequency.sort_by { |e| e[1] }
      keys.reverse!
      keys = keys.select { |e| e[1] >= avg_size }
      keys.map! { |e| e[0] }
      keys
    end

    private
      def avg_size
        @value_count / @key_frequency.size
      end
  end
end
