require 'rack/mount/utils'

module Rack::Mount
  module Generation
    module Route #:nodoc:
      attr_reader :generation_keys

      def initialize(*args)
        super

        required_params = {}
        required_defaults = {}
        @generation_keys = @defaults.dup

        @conditions.each do |method, condition|
          # TODO: don't track required_params
          required_params[method] = @conditions[method].required_params

          # TODO: don't track required_defaults
          required_defaults[method] = @defaults.dup
          @conditions[method].captures.inject({}) { |h, s| h.merge!(s.to_hash) }.keys.each { |name|
            required_defaults[method].delete(name)
            @generation_keys.delete(name) if @defaults.include?(name)
          }
          required_defaults[method]
        end
        @has_significant_params = (required_params.any? { |k, v| v.any? } || required_defaults.any? { |k, v| v.any? }) ? true : false

        @generation_keys.freeze
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
