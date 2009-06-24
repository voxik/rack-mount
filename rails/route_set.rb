module ActionController
  module Routing
    class RouteSet
      NotFound = lambda { |env|
        raise RoutingError, "No route matches #{env[::Rack::Mount::Const::PATH_INFO].inspect} with #{env.inspect}"
      }

      if defined? ActionDispatch
        PARAMETERS_KEY = 'action_dispatch.request.path_parameters'
      else
        PARAMETERS_KEY = 'rack.routing_args'
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
          conditions[:path_info].to_regexp.names.compact.map(&:to_sym)
        end
      end

      class NamedRouteCollection
        private
          def generate_optimisation_block(*args)
          end
      end

      def draw
        yield Mapper.new(self)
        @set.add_route(NotFound, :path_info => /^.*$/)
        install_helpers
        @set.freeze
      end

      def clear!
        routes.clear
        named_routes.clear
        @combined_regexp = nil
        @routes_by_controller = nil
        @set = ::Rack::Mount::RouteSet.new(:catch => -1, :parameters_key => PARAMETERS_KEY)
      end

      def add_route(path, options = {})
        clear! unless @set

        if conditions = options.delete(:conditions)
          method = conditions.delete(:method).to_s.upcase
        end

        name = options.delete(:name)

        requirements = options.delete(:requirements) || {}
        defaults = {}
        options.each do |k, v|
          if v.is_a?(Regexp)
            requirements[k.to_sym] = options.delete(k)
          else
            defaults[k.to_sym] = options.delete(k)
          end
        end

        possible_names = Routing.possible_controllers.collect { |n| Regexp.escape(n) }
        requirements[:controller] ||= Regexp.union(*possible_names)

        defaults[:action] ||= 'index' if defaults[:controller]

        if path.is_a?(String)
          path = path.gsub('.:format', '(.:format)')
          path = optionalize_trailing_dynamic_segments(path, requirements)
          glob = $1.to_sym if path =~ /\/\*(\w+)$/
          path = ::Rack::Mount::Utils.normalize_path(path)
          path = ::Rack::Mount::Strexp.compile(path, requirements, %w( / . ? ))
        end

        app = Dispatcher.new(:defaults => defaults, :glob => glob)

        conditions = { :request_method => method, :path_info => path }
        route = @set.add_route(app, conditions, defaults, name)
        route.extend(RouteExtensions)
        route
      end

      def add_named_route(name, path, options = {})
        options[:name] = name
        named_routes[name.to_sym] = add_route(path, options)
      end

      def generate(options, recall = {}, method = :generate)
        named_route = options.delete(:use_route)

        options = options_as_params(options)
        expire_on = build_expiry(options, recall)
        options.each { |k, v| options[k] = v.to_param }

        if options[:controller]
          options[:controller] = options[:controller].to_s
        end

        if !named_route && expire_on[:controller] && options[:controller] && options[:controller][0] != ?/
          old_parts = recall[:controller].split('/')
          new_parts = options[:controller].split('/')
          parts = old_parts[0..-(new_parts.length + 1)] + new_parts
          options[:controller] = parts.join('/')
        end

        options[:controller] = options[:controller][1..-1] if options[:controller] && options[:controller][0] == ?/

        merged = options.merge(recall)
        recall[:action] ||= 'index' if merged[:controller]
        recall[:action] = options.delete(:action) if options[:action] == 'index'

        path = @set.url_for(named_route, options, recall)
        if path && method == :generate_extras
          uri = URI(path)
          extras = uri.query ?
            uri.query.split('&').map { |v| v.split('=').first.to_sym }.uniq :
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

      def recognize_path(path, environment = {})
        method = (environment[:method] || "GET").to_s.upcase
        env = Rack::MockRequest.env_for(path, {:method => method})
        env['action_controller.recognize'] = true
        if result = call(env)
          status, headers, body = result
          body
        else
          raise ActionController::RoutingError
        end
      end

      def call(env)
        @set.call(env)
      end

      private
        def optionalize_trailing_dynamic_segments(path, requirements)
          path = (path =~ /^\//) ? path.dup : "/#{path}"
          optional, segments = true, []

          old_segments = path.split('/')
          old_segments.shift
          length = old_segments.length

          old_segments.reverse.each_with_index do |segment, index|
            requirements.keys.each do |required|
              if segment =~ /#{required}/
                optional = false
                break
              end
            end

            if optional && !(segment =~ /^:\w+$/) && !(segment =~ /^:\w+\(\.:format\)$/)
              optional = false
            end

            if optional && index < length - 1
              segments.unshift('(/', segment)
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
