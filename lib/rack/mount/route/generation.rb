module Rack
  module Mount
    class Route
      module Generation
        def initialize(*args)
          super

          if @path.is_a?(String)
            @segments = parse_segments_with_optionals(@path.dup)
          end
        end

        def url_for(params = {})
          params = (params || {}).dup
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
          def parse_segments_with_optionals(pattern, nest_level = 0)
            segments = []

            while segment = pattern.slice!(/^(?:|.*?[^\\])(?:\\\\)*([\(\)])/)
              segments.concat parse_segments(segment[0..-2]) if segment.length > 1
              if segment[-1, 1] == '('
                segments << parse_segments_with_optionals(pattern, nest_level + 1)
              else
                raise ArgumentError, "There are too many closing parentheses" if nest_level == 0
                return segments
              end
            end

            segments.concat parse_segments(pattern) unless pattern.empty?

            raise ArgumentError, "You have too many opening parentheses" unless nest_level == 0

            segments
          end

          def parse_segments(path)
            segments = []

            while match = (path.match(/(?:(:|\*)([a-z](?:_?[a-z0-9])*))/i))
              segment_name = match[2].to_sym

              # Handle false-positives due to escaped special characters
              if match.pre_match =~ /(?:^|[^\\])\\(?:\\\\)*$/
                segments << "#{match.pre_match[0..-2]}#{match[0]}"
              else
                segments << match.pre_match unless match.pre_match.empty?
                segments << segment_name
              end

              path = match.post_match
            end

            segments << path unless path.empty?
            segments
          end

          def generate_from_segments(segments, params, defaults, optional = false)
            if optional
              # We don't want to generate all string optional segments
              return "" if segments.all? { |s| s.is_a?(String) }
            end

            generated = segments.map do |segment|
              case segment
              when String
                segment
              when Symbol
                params[segment] || defaults[segment]
              when Array
                generate_from_segments(segment, params, defaults, true) || ""
              end
            end

            # Delete any used items from the params
            segments.each { |s| params.delete(s) if s.is_a?(Symbol) }

            generated.join
          end
      end
    end
  end
end
