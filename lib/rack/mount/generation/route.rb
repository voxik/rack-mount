require 'rack/mount/utils'
require 'uri'

module Rack
  module Mount
    module Generation
      module Route #:nodoc:
        class DynamicSegment #:nodoc:
          attr_reader :name, :requirement

          def initialize(name, requirement)
            @name, @requirement = name.to_sym, bound_expression(requirement)
            freeze
          end

          def ==(obj)
            @name == obj.name && @requirement == obj.requirement
          end

          def =~(str)
            @requirement =~ str
          end

          def to_hash
            { @name => @requirement }
          end

          def inspect
            "/(?<#{@name}>#{@requirement.source})/"
          end

          private
            def bound_expression(regexp)
              source, options = regexp.source, regexp.options
              source = "\\A#{source}\\Z"
              Regexp.compile(source, options).freeze
            end
        end

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

          unless path = generate_from_segments(@conditions[method].segments, params, merged, @defaults)
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

        private
          def generate_from_segments(segments, params, merged, defaults, optional = false)
            if optional
              return Const::EMPTY_STRING if segments.all? { |s| s.is_a?(String) }
              return Const::EMPTY_STRING unless segments.flatten.any? { |s|
                params[s.name] if s.is_a?(DynamicSegment)
              }
              return Const::EMPTY_STRING if segments.any? { |segment|
                if segment.is_a?(DynamicSegment)
                  value = params[segment.name] || defaults[segment.name]
                  value.nil? || segment !~ value.to_s || params[segment.name] == defaults[segment.name]
                end
              }
            end

            generated = segments.map do |segment|
              case segment
              when String
                segment
              when DynamicSegment
                value = merged[segment.name] || defaults[segment.name]
                if value && segment =~ value.to_s
                  URI.escape(value.to_s)
                else
                  return
                end
              when Array
                generate_from_segments(segment, params, merged, defaults, true) || Const::EMPTY_STRING
              end
            end

            # Delete any used items from the params
            segments.each { |s| params.delete(s.name) if s.is_a?(DynamicSegment) }

            generated.join
          end
      end
    end
  end
end
