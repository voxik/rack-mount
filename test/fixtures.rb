autoload :BasicSet, 'fixtures/basic_set'
autoload :BasicSetMap, 'fixtures/basic_set_map'
autoload :DefaultSet, 'fixtures/default_set'
autoload :EchoApp, 'fixtures/echo_app'
autoload :LinearBasicSet, 'fixtures/linear_basic_set'
autoload :NestedSetA, 'fixtures/nested_set_a'
autoload :NestedSetB, 'fixtures/nested_set_b'
autoload :OptimizedBasicSet, 'fixtures/optimized_basic_set'

module ControllerConstants
  def const_missing(name)
    if name.to_s =~ /Controller$/
      const_set(name, EchoApp)
    else
      super
    end
  end
end

module Account
  extend ControllerConstants
end

Object.extend(ControllerConstants)

def supports_named_captures?
  require 'rack/mount/utils'
  Regin.regexp_supports_named_captures?
end
