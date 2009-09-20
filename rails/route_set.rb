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

      def empty?
        @set.length == 0
      end

      undef :add_route
      def add_route(path, options = {})
        if conditions = options.delete(:conditions)
          method = conditions.delete(:method)
          method = method.to_s.upcase if method
        end

        name = options.delete(:_name)

        requirements = options.delete(:requirements) || {}
        defaults = {}
        options.each do |k, v|
          if v.is_a?(Regexp)
            if value = options.delete(k)
              requirements[k.to_sym] = value
            end
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

        if method && !HTTP_METHODS.include?(method.downcase.to_sym)
          raise ArgumentError
        end

        conditions = {}
        conditions[:request_method] = method if method
        conditions[:path_info] = path if path

        route = @set.add_route(app, conditions, defaults, name)
        route.extend(RouteExtensions)
        route
      end

      undef :add_named_route
      def add_named_route(name, path, options = {})
        options[:_name] = name
        named_routes[name.to_sym] = add_route(path, options)
      end

      undef :generate
      def generate(options, recall = {}, method = :generate)
        named_route = options.delete(:use_route)

        options = options_as_params(options)
        expire_on = build_expiry(options, recall)

        # TODO: This is a complete mess
        not_expired = expire_on.inject([]) { |ary, (key, expired)|
          ary << key if expired == false
          ary
        }
        recover_others = false
        if recall[:controller] && options[:controller] != recall[:controller] && not_expired.delete(:controller)
          options[:controller] ||= recall[:controller]
          recover_others = true
        end
        if !expire_on[:action] && recall[:action] && options[:action] != recall[:action] && (recover_others || not_expired.delete(:action))
          options[:action] ||= recall[:action]
          recover_others = true
        end
        if !expire_on[:action] && recover_others
          not_expired.each do |key|
            options[key] ||= recall[key]
          end
        end

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
        env = Rack::MockRequest.env_for(path, {:method => method})
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
            elsif optional && segment =~ /^:\w+$/ && segment != ":action" && segment != ":id"
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
