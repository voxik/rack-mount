module ActionController
  module Routing
    class RouteSet
      NotFound = lambda { |env|
        raise RoutingError, "No route matches #{env[::Rack::Mount::Const::PATH_INFO].inspect} with #{env.inspect}"
      }

      if defined? ActionDispatch
        PARAMETERS_KEY = 'action_dispatch.request.path_parameters'
      else
        PARAMETERS_KEY = 'action_controller.request.path_parameters'
      end

      class Dispatcher
        def initialize(options = {})
          defaults = options[:defaults]
          @glob_param = options.delete(:glob)
        end

        def call(env)
          params = env[PARAMETERS_KEY]
          merge_default_action!(params)
          split_glob_param!(params) if @glob_param
          params.each { |key, value| params[key] = URI.unescape(value) if value.is_a?(String) }

          if env['action_controller.recognize']
            [200, {}, params]
          else
            controller = controller(params)
            if defined? ActionDispatch
              controller.action(params[:action]).call(env)
            else
              controller.call(env).to_a
            end
          end
        end

        private
          def controller(params)
            if params && params.has_key?(:controller)
              controller = "#{params[:controller].camelize}Controller"
              ActiveSupport::Inflector.constantize(controller)
            end
          end

          def merge_default_action!(params)
            params[:action] ||= 'index'
          end

          def split_glob_param!(params)
            params[@glob_param] = params[@glob_param].split('/')
          end
      end

      module RouteExtensions
        def segment_keys
          conditions[:path_info].names.compact.map { |key| key.to_sym }
        end
      end

      class NamedRouteCollection
        private
          def generate_optimisation_block(*args)
          end
      end

      undef :draw
      def draw
        clear!
        yield Mapper.new(self)
        @set.add_route(NotFound)
        install_helpers
        @set.freeze
      end

      undef :clear!
      def clear!
        routes.clear
        named_routes.clear
        @combined_regexp = nil
        @routes_by_controller = nil
        @set = ::Rack::Mount::RouteSet.new(:parameters_key => PARAMETERS_KEY)
      end

      undef :add_route
      def add_route(path, options = {})
        options = options.dup

        if conditions = options.delete(:conditions)
          conditions = conditions.dup
          method = [conditions.delete(:method)].flatten.compact
          method.map! { |m|
            m = m.to_s.upcase

            if m == "HEAD"
              raise ArgumentError, "HTTP method HEAD is invalid in route conditions. Rails processes HEAD requests the same as GETs, returning just the response headers"
            end

            unless HTTP_METHODS.include?(m.downcase.to_sym)
              raise ArgumentError, "Invalid HTTP method specified in route conditions"
            end

            m
          }

          if method.length > 1
            method = Regexp.union(*method)
          elsif method.length == 1
            method = method.first
          else
            method = nil
          end
        end

        path_prefix = options.delete(:path_prefix)
        name_prefix = options.delete(:name_prefix)
        namespace  = options.delete(:namespace)

        name = options.delete(:_name)
        name = "#{name_prefix}#{name}" if name_prefix

        requirements = options.delete(:requirements) || {}
        defaults = options.delete(:defaults) || {}
        options.each do |k, v|
          if v.is_a?(Regexp)
            if value = options.delete(k)
              requirements[k.to_sym] = value
            end
          else
            value = options.delete(k)
            defaults[k.to_sym] = value.is_a?(Symbol) ? value : value.to_param
          end
        end

        requirements.each do |_, requirement|
          if requirement.source =~ %r{\A(\\A|\^)|(\\Z|\\z|\$)\Z}
            raise ArgumentError, "Regexp anchor characters are not allowed in routing requirements: #{requirement.inspect}"
          end
          if requirement.multiline?
            raise ArgumentError, "Regexp multiline option not allowed in routing requirements: #{requirement.inspect}"
          end
        end

        possible_names = Routing.possible_controllers.collect { |n| Regexp.escape(n) }
        requirements[:controller] ||= Regexp.union(*possible_names)

        if defaults[:controller]
          defaults[:action] ||= 'index'
          defaults[:controller] = defaults[:controller].to_s
          defaults[:controller] = "#{namespace}#{defaults[:controller]}" if namespace
        end

        if defaults[:action]
          defaults[:action] = defaults[:action].to_s
        end

        if path.is_a?(String)
          path = "#{path_prefix}/#{path}" if path_prefix
          path = path.gsub('.:format', '(.:format)')
          path = optionalize_trailing_dynamic_segments(path, requirements, defaults)
          glob = $1.to_sym if path =~ /\/\*(\w+)$/
          path = ::Rack::Mount::Utils.normalize_path(path)
          path = ::Rack::Mount::Strexp.compile(path, requirements, %w( / . ? ))

          if glob && !defaults[glob].blank?
            raise RoutingError, "paths cannot have non-empty default values"
          end
        end

        app = Dispatcher.new(:defaults => defaults, :glob => glob)

        conditions = {}
        conditions[:request_method] = method if method
        conditions[:path_info] = path if path

        route = @set.add_route(app, conditions, defaults, name)
        route.extend(RouteExtensions)
        routes << route
        route
      end

      undef :add_named_route
      def add_named_route(name, path, options = {})
        options[:_name] = name
        route = add_route(path, options)
        named_routes[route.name] = route
        route
      end

      undef :generate
      def generate(options, recall = {}, method = :generate)
        options, recall = options.dup, recall.dup
        named_route = options.delete(:use_route)

        options = options_as_params(options)
        expire_on = build_expiry(options, recall)

        recall[:action] ||= 'index' if options[:controller] || recall[:controller]

        if recall[:controller] && (!options.has_key?(:controller) || options[:controller] == recall[:controller])
          options[:controller] = recall.delete(:controller)

          if recall[:action] && (!options.has_key?(:action) || options[:action] == recall[:action])
            options[:action] = recall.delete(:action)

            if recall[:id] && (!options.has_key?(:id) || options[:id] == recall[:id])
              options[:id] = recall.delete(:id)
            end
          end
        end

        options[:controller] = options[:controller].to_s if options[:controller]

        if !named_route && expire_on[:controller] && options[:controller] && options[:controller][0] != ?/
          old_parts = recall[:controller].split('/')
          new_parts = options[:controller].split('/')
          parts = old_parts[0..-(new_parts.length + 1)] + new_parts
          options[:controller] = parts.join('/')
        end

        options[:controller] = options[:controller][1..-1] if options[:controller] && options[:controller][0] == ?/

        merged = options.merge(recall)
        if options.has_key?(:action) && options[:action].nil?
          options.delete(:action)
          recall[:action] = 'index'
        end
        recall[:action] = options.delete(:action) if options[:action] == 'index'

        path = @set.url(named_route, options, recall)
        if path && method == :generate_extras
          uri = URI(path)
          extras = uri.query ?
            Rack::Utils.parse_nested_query(uri.query).keys.map { |k| k.to_sym } :
            []
          [uri.path, extras]
        elsif path
          path
        else
          raise RoutingError, "No route matches #{options.inspect}"
        end
      rescue Rack::Mount::RoutingError
        raise RoutingError, "No route matches #{options.inspect}"
      end

      undef :recognize_path
      def recognize_path(path, environment = {}, rescue_error = true)
        method = (environment[:method] || "GET").to_s.upcase
        path = URI.escape(path)

        begin
          env = Rack::MockRequest.env_for(path, {:method => method})
        rescue URI::InvalidURIError => e
          raise RoutingError, e.message
        end

        env['action_controller.recognize'] = true
        env['action_controller.rescue_error'] = rescue_error
        status, headers, body = call(env)
        body
      end

      undef :call
      def call(env)
        @set.call(env)
      rescue ActionController::RoutingError => e
        raise e if env['action_controller.rescue_error'] == false

        method, path = env['REQUEST_METHOD'].downcase.to_sym, env['PATH_INFO']

        # Route was not recognized. Try to find out why (maybe wrong verb).
        allows = HTTP_METHODS.select { |verb|
          begin
            recognize_path(path, {:method => verb}, false)
          rescue ActionController::RoutingError
            nil
          end
        }

        if !HTTP_METHODS.include?(method)
          raise NotImplemented.new(*allows)
        elsif !allows.empty?
          raise MethodNotAllowed.new(*allows)
        else
          raise e
        end
      end

      private
        def optionalize_trailing_dynamic_segments(path, requirements, defaults)
          path = (path =~ /^\//) ? path.dup : "/#{path}"
          optional, segments = true, []

          required_segments = requirements.keys
          required_segments -= defaults.keys.compact

          old_segments = path.split('/')
          old_segments.shift
          length = old_segments.length

          old_segments.reverse.each_with_index do |segment, index|
            required_segments.each do |required|
              if segment =~ /#{required}/
                optional = false
                break
              end
            end

            if optional
              if segment == ":id" && segments.include?(":action")
                optional = false
              elsif segment == ":controller" || segment == ":action" || segment == ":id"
                # Ignore
              elsif !(segment =~ /^:\w+$/) &&
                  !(segment =~ /^:\w+\(\.:format\)$/)
                optional = false
              elsif segment =~ /^:(\w+)$/
                if defaults.has_key?($1.to_sym)
                  defaults.delete($1.to_sym)
                else
                  optional = false
                end
              end
            end

            if optional && index < length - 1
              segments.unshift('(/', segment)
              segments.push(')')
            elsif optional
              segments.unshift('/(', segment)
              segments.push(')')
            else
              segments.unshift('/', segment)
            end
          end

          segments.join
        end
    end
  end
end
