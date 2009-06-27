require 'rack'

module Rack #:nodoc:
  module Mount #:nodoc:
    autoload :Condition, 'rack/mount/condition'
    autoload :Const, 'rack/mount/const'
    autoload :Generation, 'rack/mount/generation'
    autoload :MetaMethod, 'rack/mount/meta_method'
    autoload :Mixover, 'rack/mount/mixover'
    autoload :Multimap, 'rack/mount/multimap'
    autoload :PathCondition, 'rack/mount/condition'
    autoload :Prefix, 'rack/mount/prefix'
    autoload :Recognition, 'rack/mount/recognition'
    autoload :RegexpWithNamedGroups, 'rack/mount/regexp_with_named_groups'
    autoload :Route, 'rack/mount/route'
    autoload :RouteSet, 'rack/mount/route_set'
    autoload :RoutingError, 'rack/mount/exceptions'
    autoload :Strexp, 'rack/mount/strexp'
    autoload :StringScanner, 'rack/mount/strscan'
    autoload :Utils, 'rack/mount/utils'
  end
end

autoload :URI, 'uri'
