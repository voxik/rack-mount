require 'rack/mount/utils'

module Rack::Mount
  module Generation
    module Route #:nodoc:
      attr_reader :generation_keys

      def initialize(*args)
        super

        # TODO: build this from conditional helpers
        @generation_keys = @defaults.dup
        @conditions.each do |method, condition|
          @conditions[method].captures.inject({}) { |h, s| h.merge!(s.to_hash) }.keys.each { |name|
            @generation_keys.delete(name) if @defaults.include?(name)
          }
        end
        @generation_keys.freeze

        @has_significant_params = @conditions.any? { |method, condition|
          condition.required_params.any? || condition.required_defaults.any?
        }
      end

      def significant_params?
        @has_significant_params
      end

      def generate(methods, params = {}, recall = {}, options = {})
        if methods.is_a?(Array)
          result = methods.map { |m| generate_method(m, params, recall, options) || (return nil) }
        else
          result = generate_method(methods, params, recall, options)
        end

        if result
          @defaults.each do |key, value|
            params.delete(key) if params[key] == value
          end
        end

        result
      end

      private
        def generate_method(method, params, recall, options)
          if condition = @conditions[method]
            condition.generate(params, recall, options)
          end
        end
    end
  end
end
