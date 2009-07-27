require 'rack'

module Rack #:nodoc:
  module Mount #:nodoc:
    autoload :Analyzer, 'rack/mount/analyzer'
    autoload :Condition, 'rack/mount/condition'
    autoload :Const, 'rack/mount/const'
    autoload :MetaMethod, 'rack/mount/meta_method'
    autoload :Mixover, 'rack/mount/mixover'
    autoload :Multimap, 'rack/mount/multimap'
    autoload :Prefix, 'rack/mount/prefix'
    autoload :RegexpWithNamedGroups, 'rack/mount/regexp_with_named_groups'
    autoload :Route, 'rack/mount/route'
    autoload :RouteSet, 'rack/mount/route_set'
    autoload :RoutingError, 'rack/mount/exceptions'
    autoload :SplitCondition, 'rack/mount/condition'
    autoload :Strexp, 'rack/mount/strexp'
    autoload :Utils, 'rack/mount/utils'

    module Generation #:nodoc:
      autoload :Condition, 'rack/mount/generation/condition'
      autoload :Route, 'rack/mount/generation/route'
      autoload :RouteSet, 'rack/mount/generation/route_set'
    end

    module Recognition #:nodoc:
      autoload :CodeGeneration, 'rack/mount/recognition/code_generation'
      autoload :Condition, 'rack/mount/recognition/condition'
      autoload :Route, 'rack/mount/recognition/route'
      autoload :RouteSet, 'rack/mount/recognition/route_set'
    end
  end
end
