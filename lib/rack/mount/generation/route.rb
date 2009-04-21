module Rack
  module Mount
    module Generation
      module Route
        class DynamicSegment
          attr_reader :name, :requirement

          def initialize(name, requirement)
            @name, @requirement = name.to_sym, requirement
          end

          def ==(obj)
            @name == obj.name && @requirement == obj.requirement
          end
        end

        def initialize(*args)
          super

          @segments = segments(@path).freeze
          @required_params = @segments.find_all { |s|
            s.is_a?(DynamicSegment)
          }.map { |s| s.name }.freeze
        end

        def url_for(params = {})
          params = (params || {}).dup

          return nil if @segments.empty?
          return nil unless @required_params.all? { |p| params.include?(p) }

          path = generate_from_segments(@segments, params, @defaults)

          @defaults.each do |key, value|
            params.delete(key)
          end

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
              if part.is_a?(Utils::Capture)
                if part.named?
                  source = part.map { |p| p.is_a?(Array) ? "(#{p.join})?" : p }.join
                  requirement = Regexp.compile(source)
                  s << DynamicSegment.new(part.name, requirement)
                else
                  s << parse_segments(part)
                end
              else
                source = part.gsub('\\.', '.').gsub('\\/', '/')
                if Regexp.compile("^(#{part})$") =~ source
                  s << source
                else
                  raise ArgumentError, "failed to parse #{part.inspect}"
                end
              end
            end
            s
          end

          def generate_from_segments(segments, params, defaults, optional = false)
            if optional
              return Const::EMPTY_STRING if segments.all? { |s| s.is_a?(String) }
              return Const::EMPTY_STRING if segments.flatten.all? { |s|
                if s.is_a?(DynamicSegment) && params[s.name]
                  params[s.name].to_s !~ s.requirement
                else
                  true
                end
              }
            end

            generated = segments.map do |segment|
              case segment
              when String
                segment
              when DynamicSegment
                params[segment.name] || defaults[segment.name]
              when Array
                generate_from_segments(segment, params, defaults, true) || Const::EMPTY_STRING
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
