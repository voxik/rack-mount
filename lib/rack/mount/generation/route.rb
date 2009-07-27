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

        def generate(method, params = {}, recall = {})
          params = (params || {}).dup
          merged = recall.merge(params)

          return nil unless @conditions[method]
          return nil if @conditions[method].segments.empty?
          return nil unless @required_params[method].all? { |p| merged.include?(p) }
          return nil unless @required_defaults[method].all? { |k, v| merged[k] == v }

          unless path = @conditions[method].generate(params, merged, @defaults)
            return
          end

          @defaults.each do |key, value|
            if params[key] == value
              params.delete(key)
            end
          end

          params.delete_if { |k, v| v.nil? }
          if params.any?
            path << "?#{Rack::Utils.build_query(params)}"
          end

          path
        end
      end
    end
  end
end
