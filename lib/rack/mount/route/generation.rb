module Rack
  module Mount
    class Route
      module Generation
        def initialize(*args)
          super

          @segments = Utils.build_generation_segments(@recognizer).freeze
          @required_params = @segments.find_all { |s| s.is_a?(Symbol) }.freeze
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
          def generate_from_segments(segments, params, defaults, optional = false)
            if optional
              return Const::EMPTY_STRING if segments.all? { |s| s.is_a?(String) }
              return Const::EMPTY_STRING if segments.flatten.all? { |s|
                if s.is_a?(Symbol) && params[s]
                  if @requirements[s]
                    params[s].to_s !~ @requirements[s]
                  else
                    false
                  end
                else
                  true
                end
              }
            end

            generated = segments.map do |segment|
              case segment
              when String
                segment
              when Symbol
                params[segment] || defaults[segment]
              when Array
                generate_from_segments(segment, params, defaults, true) || Const::EMPTY_STRING
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
