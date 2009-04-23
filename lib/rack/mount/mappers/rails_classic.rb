require 'action_controller'

module Rack
  module Mount
    module Mappers
      class RailsClassic
        class RoutingError < StandardError; end

        NotFound = lambda { |env|
          raise RoutingError, "No route matches #{env[Const::PATH_INFO].inspect} with #{env.inspect}"
        }

        class Dispatcher
          def initialize(options = {})
            defaults = options[:defaults]
            @glob_param = options.delete(:glob)
            @app = controller(defaults) if bind_controller_const?
          end

          def call(env)
            params = env[Const::RACK_ROUTING_ARGS]
            app = @app || controller(params)
            merge_default_action!(params)
            split_glob_param!(params) if @glob_param

            # TODO: Rails response is not finalized by the controller
            app.call(env).to_a
          end

          private
            def bind_controller_const?
              if defined? Rails
                Rails.env.production?
              else
                true
              end
            end

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
  
        class RouteSet
          attr_accessor :configuration_files

          def initialize
            self.configuration_files = []

            clear!
          end

          def named_routes
            @set.instance_variable_get('@named_routes')
          end

          def draw
            yield ActionController::Routing::RouteSet::Mapper.new(self)
            @set.add_route(NotFound, :path => /.*/)
            install_helpers
            @set.freeze
          end

          def clear!
            @set = ::Rack::Mount::RouteSet.new
          end

          def install_helpers(destinations = [ActionController::Base, ActionView::Base], regenerate_code = false)
            mod ||= Module.new
            mod.instance_methods.each do |selector|
              mod.class_eval { remove_method selector }
            end

            named_routes.each do |name, route|
              url_options  = route.defaults.merge(:use_route => name, :only_path => false)
              path_options = route.defaults.merge(:use_route => name, :only_path => true)
              segment_keys = route.path.names.compact.map(&:to_sym)

              { :path => path_options, :url => url_options }.each do |kind, options|
                mod.module_eval <<-end_eval
                  def hash_for_#{name}_#{kind}(options = nil)
                    options ? #{options.inspect}.merge(options) : #{options.inspect}
                  end
                  protected :hash_for_#{name}_#{kind}

                  def #{name}_#{kind}(*args)
                    opts = if args.empty? || Hash === args.first
                      args.first || {}
                    else
                      options = args.extract_options!
                      args = args.zip(#{segment_keys.inspect}).inject({}) do |h, (v, k)|
                        h[k] = v
                        h
                      end
                      options.merge(args)
                    end
                    url_for(hash_for_#{name}_#{kind}(opts))
                  end
                  protected :#{name}_#{kind}
                end_eval
              end
            end

            Array(destinations).each do |d|
              d.module_eval { include ActionController::Routing::Helpers }
              d.__send__(:include, mod)
            end
          end

          def add_configuration_file(path)
            self.configuration_files << path
          end

          def load!
            clear!
            load_routes!
          end
          alias reload! load!

          def reload
            if configuration_files.any? && @routes_last_modified
              if routes_changed_at == @routes_last_modified
                return # routes didn't change, don't reload
              else
                @routes_last_modified = routes_changed_at
              end
            end

            load!
          end

          def load_routes!
            if configuration_files.any?
              configuration_files.each { |config| load(config) }
              @routes_last_modified = routes_changed_at
            end
          end

          def routes_changed_at
            routes_changed_at = nil

            configuration_files.each do |config|
              config_changed_at = ::File.stat(config).mtime

              if routes_changed_at.nil? || config_changed_at > routes_changed_at
                routes_changed_at = config_changed_at 
              end
            end

            routes_changed_at
          end

          def add_route(path, options = {})
            if path.is_a?(String)
              path = path.gsub('.:format', '(.:format)')
              path = optionalize_trailing_dynamic_segments(path)
            end

            if conditions = options.delete(:conditions)
              method = conditions.delete(:method)
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

            if path.is_a?(String)
              glob = $1.to_sym if path =~ /\/\*(\w+)$/
              path = Utils.convert_segment_string_to_regexp(path, requirements, %w( / . ? ))
            end

            app = Dispatcher.new(:defaults => defaults, :glob => glob)

            conditions = { :method => method, :path => path }
            @set.add_route(app, conditions, defaults, name)
          end

          def add_named_route(name, path, options = {})
            options[:name] = name
            add_route(path, options)
          end

          def generate(options, recall = {}, method = :generate)
            named_route = options.delete(:use_route)
            options = recall.merge(options)
            options.each { |k, v| options[k] = v.to_param }
            @set.url_for(named_route, options)
          end

          def url_for(*args)
            @set.url_for(*args)
          end

          def call(env)
            @set.call(env)
          end

          private
            def optionalize_trailing_dynamic_segments(path)
              path = (path =~ /^\//) ? path.dup : "/#{path}"
              optional, segments = true, []

              old_segments = path.split('/')
              old_segments.shift
              length = old_segments.length

              old_segments.reverse.each_with_index do |segment, index|
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
  end
end
