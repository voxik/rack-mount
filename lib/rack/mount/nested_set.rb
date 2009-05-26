begin
  require 'fuzzy_nested_multimap'
rescue LoadError
  $: << File.expand_path(File.join(File.dirname(__FILE__), 'vendor/multimap'))
  require 'fuzzy_nested_multimap'
end

module Rack
  module Mount
    class NestedSet < FuzzyNestedMultimap #:nodoc:
      def lists
        lists = []
        each_value_with_default { |value| lists << value }
        lists
      end

      def height
        lists.max { |a, b| a.length <=> b.length }.length
      end

      protected
        def each_value_with_default
          each_value = Proc.new do |value|
            if value.respond_to?(:each_value_with_default)
              value.each_value_with_default do |nested_value|
                yield nested_value
              end
            else
              yield value
            end
          end

          hash_each_pair { |_, value| each_value.call(value) }
          each_value.call(default)
        end
    end
  end
end
