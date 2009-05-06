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
require 'rack/mount/mappers/simple'

module Rack
  class Router
    module Routable
      def prepare(options = {}, &block)
        options.merge!(:parameters_key => 'rack_router.params')
        @set = Rack::Mount::RouteSet.new(options).prepare(&block)
      end

      def url(name, params = {}, fallback = {})
        @set.url_for(name, params)
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
