module Rack
  module Mount
    module Generation
      module Route #:nodoc:
        class DynamicSegment #:nodoc:
          attr_reader :name, :requirement

          def initialize(name, requirement)
            @name, @requirement = name.to_sym, bound_expression(requirement)
          end

          def ==(obj)
            @name == obj.name && @requirement == obj.requirement
          end

          def =~(str)
            @requirement =~ str
          end

          def inspect
            "/(?<#{@name}>#{@requirement.source})/"
          end

          private
            def bound_expression(regexp)
              source, options = regexp.source, regexp.options
              source = "^#{source}$"
              Regexp.compile(source, options)
            end
        end

        attr_reader :generation_keys

        def initialize(*args)
          super

          # TODO: Don't explict check for :path_info condition
          @segments = @conditions.has_key?(:path_info) ?
            segments(@conditions[:path_info].to_regexp).freeze :
            []

          # TODO: Way too may types of requirement hashes,
          # need to consolidate
          @required_params = @segments.find_all { |s|
            s.is_a?(DynamicSegment) && !@defaults.include?(s.name)
          }.map { |s| s.name }.freeze
          @generation_keys = @defaults.dup
          @segments.flatten.each { |s|
            if s.is_a?(DynamicSegment) && @defaults.include?(s.name)
              @generation_keys.delete(s.name)
            end
          }
          @generation_keys.freeze
          @required_defaults = @defaults.dup
          @segments.flatten.each { |s|
            if s.is_a?(DynamicSegment)
              @required_defaults.delete(s.name)
            end
          }
          @required_defaults
        end

        def generate(params = {}, recall = {})
          params = (params || {}).dup
          merged = recall.merge(params)

          return nil if @segments.empty?
          return nil unless @required_params.all? { |p| merged.include?(p) }
          return nil unless @required_defaults.all? { |k, v| merged[k] == v }

          unless path = generate_from_segments(@segments, params, merged, @defaults)
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
          # Segment data structure used for generations
          # => ['/people', ['.', :format]]
          def segments(regexp)
            parse_segments(Utils.extract_regexp_parts(regexp))
          rescue ArgumentError
            []
          end

          def parse_segments(segments)
            s = []
            segments.each do |part|
              if part.is_a?(String) && part == '$'
                return s
              elsif part.is_a?(Utils::Capture)
                if part.named?
                  source = part.map { |p| p.to_s }.join
                  requirement = Regexp.compile(source)
                  s << DynamicSegment.new(part.name, requirement)
                else
                  s << parse_segments(part)
                end
              else
                part = part.gsub('\\/', '/')
                static = Utils.extract_static_regexp(part)
                if static.is_a?(String)
                  s << static
                else
                  raise ArgumentError, "failed to parse #{part.inspect}"
                end
              end
            end

            s
          end

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
