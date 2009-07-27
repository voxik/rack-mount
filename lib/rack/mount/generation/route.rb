require 'rack/mount/utils'
require 'uri'

module Rack
  module Mount
    module Generation
      module Route #:nodoc:
        attr_reader :generation_keys

        def initialize(*args)
          super

          @required_params = {}
          @required_defaults = {}
          @generation_keys = @defaults.dup

          @conditions.each do |method, condition|
            @required_params[method] = @conditions[method].required_keys.reject { |s| @defaults.include?(s) }.freeze
            @required_defaults[method] = @defaults.dup

            condition.requirements.keys.each { |name|
              @required_defaults[method].delete(name)
              @generation_keys.delete(name) if @defaults.include?(name)
            }

            @required_defaults[method].freeze
          end

          @required_params.freeze
          @required_defaults.freeze
          @generation_keys.freeze
        end

        def url(params = {}, recall = {})
          params = (params || {}).dup
          merged = recall.merge(params)

          unless part = generate_method(:path_info, params, merged, @defaults)
            return
          end

          @defaults.each do |key, value|
            if params[key] == value
              params.delete(key)
            end
          end

          params.delete_if { |k, v| v.nil? }
          if params.any?
            part << "?#{Rack::Utils.build_query(params)}"
          end

          part
        end

        def generate(methods, params = {}, recall = {})
          return url(params, recall) if methods == :__url__
          params = (params || {}).dup
          merged = recall.merge(params)
          if methods.is_a?(Array)
            methods.map { |m| generate_method(m, params, merged, @defaults) || (return nil) }
          else
            generate_method(methods, params, merged, @defaults)
          end
        end

        private
          def generate_method(method, params, merged, defaults)
            return nil unless condition = @conditions[method]
            return nil if condition.segments.empty?
            return nil unless @required_params[method].all? { |p| merged.include?(p) }
            return nil unless @required_defaults[method].all? { |k, v| merged[k] == v }
            condition.generate(params, merged, defaults)
          end
      end
    end
  end
end
