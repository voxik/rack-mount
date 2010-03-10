require 'rack/mount/utils'

module Rack::Mount
  module Generation
    module Route #:nodoc:
      def initialize(*args)
        super

        @has_significant_params = @conditions.any? { |method, condition|
          (condition.respond_to?(:required_params) && condition.required_params.any?) ||
            (condition.respond_to?(:required_defaults) && condition.required_defaults.any?)
        }
      end

      def generation_keys
        @conditions.inject({}) { |keys, (method, condition)|
          if condition.respond_to?(:required_defaults)
            keys.merge!(condition.required_defaults)
          else
            keys
          end
        }
      end

      def significant_params?
        @has_significant_params
      end

      def generate(method, params = {}, recall = {}, options = {})
        if method.nil?
          result = @conditions.inject({}) { |h, (m, condition)|
            if condition.respond_to?(:generate)
              h[m] = condition.generate(params, recall, options)
            end
            h
          }
          return nil if result.values.compact.empty?
        else
          if condition = @conditions[method]
            if condition.respond_to?(:generate)
              result = condition.generate(params, recall, options)
            end
          end
        end

        if result
          @defaults.each do |key, value|
            params.delete(key) if params[key] == value
          end
        end

        result
      end
    end
  end
end
