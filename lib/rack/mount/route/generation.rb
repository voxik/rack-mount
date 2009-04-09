module Rack
  module Mount
    class Route
      module Generation
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
