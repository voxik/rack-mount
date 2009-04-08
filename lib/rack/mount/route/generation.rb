module Rack
  module Mount
    class Route
      module Generation
        def url_for(params = {})
          params = (params || {}).dup
          path = @path.dup
          @params.each do |param|
            path.sub!(":#{param}", params.delete(param))
            path.sub!(/\(\/(.+)\)/, '/\1')
          end
          @defaults.each do |key, value|
            params.delete(key)
          end

          if params.any?
            path << "?#{Rack::Utils.build_query(params)}"
          end

          path
        end
      end
    end
  end
end
