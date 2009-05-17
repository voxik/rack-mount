# Shim to run Rack::Router specs
#
# diff --git a/spec/spec_helper.rb b/spec/spec_helper.rb
# index 7b4515c..adbd8b5 100644
# --- a/spec/spec_helper.rb
# +++ b/spec/spec_helper.rb
# @@ -1,11 +1,7 @@
# -$LOAD_PATH.unshift File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))
# -
#  require "rubygems"
#  require "spec"
# -require "rack/router"
# -if ENV['optimizations']
# -  require "rack/router/optimizations"
# -end
# +
# +require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'test', 'lib', 'rack_router'))
#  
#  module Spec
#    module Helpers

$LOAD_PATH.unshift File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'lib'))

require 'rack/mount'

module Rack
  class Router
    class SimpleMapper
      def initialize(set)
        @set = set
      end

      def map(*args)
        options = args.last.is_a?(Hash) ? args.pop : {}

        app = options[:to]
        path = args[0]
        if method = args[1]
          method = method.to_s.upcase unless method.is_a?(Regexp)
        end
        defaults = options[:with]
        name = options[:name]

        conditions, requirements = {}, {}

        (options[:conditions] || {}).each do |k,v|
          v = v.to_s unless v.is_a?(Regexp)
          @set.valid_conditions.include?(k.to_sym) ?
            conditions[k] = v :
            requirements[k] = v
        end

        if path.is_a?(String)
          path = Rack::Mount::Utils.normalize_path(path)
        end

        conditions[:request_method] = method if method
        conditions[:path_info] = path if path

        conditions = conditions.inject({}) do |conditions, (key, value)|
          conditions[key] = value.is_a?(String) ?
            Rack::Mount::Utils.convert_segment_string_to_regexp(value, requirements, %w( / . ? )) :
            value
          conditions
        end

        @set.add_route(app, conditions, defaults, name)
      end
    end

    module Routable
      def prepare(options = {}, &block)
        options[:parameters_key] ||= 'rack_router.params'
        @set = Rack::Mount::RouteSet.new(options)
        yield SimpleMapper.new(@set)
        @set.freeze
      end

      def url(name, params = {}, fallback = {})
        params = params.merge(fallback)
        @set.url_for(name, params) || raise(ArgumentError)
      end

      def call(env)
        @set.call(env)
      end
    end

    include Routable

    def initialize(app = nil, options = {}, &block)
      prepare(options, &block)
    end
  end
end
