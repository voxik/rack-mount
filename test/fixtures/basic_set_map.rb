BasicSetMap = Proc.new do |set|
  set.add_route(EchoApp, :path => '/people', :method => 'get', :defaults => { :controller => 'people', :action => 'index' })
  set.add_route(EchoApp, :path => '/people', :method => 'post', :defaults => { :controller => 'people', :action => 'create' })
  set.add_route(EchoApp, :path => '/people/new', :method => 'get', :defaults => { :controller => 'people', :action => 'new' })
  set.add_route(EchoApp, :path => '/people/:id/edit', :method => 'get', :defaults => { :controller => 'people', :action => 'edit' })
  set.add_route(EchoApp, :path => '/people/:id', :method => 'get', :defaults => { :controller => 'people', :action => 'show' })
  set.add_route(EchoApp, :path => '/people/:id', :method => 'put', :defaults => { :controller => 'people', :action => 'update' })
  set.add_route(EchoApp, :path => '/people/:id', :method => 'delete', :defaults => { :controller => 'people', :action => 'destroy' })

  set.add_route(EchoApp, :path => '/', :defaults => { :controller => 'homepage' })

  set.add_route(EchoApp, :name => :geocode, :path => '/geocode/:postalcode', :defaults => { :controller => 'geocode', :action => 'show' }, :requirements => { :postalcode => /\d{5}(-\d{4})?/ })
  set.add_route(EchoApp, :name => :geocode2, :path => '/geocode2/:postalcode', :defaults => { :controller => 'geocode', :action => 'show' }, :requirements => { :postalcode => /\d{5}(-\d{4})?/ })

  set.add_route(EchoApp, :name => :login, :path => '/login', :method => 'get', :defaults => { :controller => 'sessions', :action => 'new' })
  set.add_route(EchoApp, :path => '/login', :method => 'post', :defaults => { :controller => 'sessions', :action => 'create' })
  set.add_route(EchoApp, :name => :logout, :path => '/logout', :method => 'delete', :defaults => { :controller => 'sessions', :action => 'destroy' })

  set.add_route(EchoApp, :path => '/global/:action', :defaults => { :controller => 'global' })
  set.add_route(EchoApp, :name => :export_request, :path => '/global/export', :defaults => { :controller => 'global', :action => 'export' })
  set.add_route(EchoApp, :name => :hide_notice, :path => '/global/hide_notice', :defaults => { :controller => 'global', :action => 'hide_notice' })
  set.add_route(EchoApp, :name => :export_download, :path => '/export/:id/:file', :defaults => { :controller => 'global', :action => 'export' }, :requirements => { :file => /.*/ })

  set.add_route(EchoApp, :path => '/account/subscription', :method => 'get', :defaults => { :controller => 'account/subscription', :action => 'index' })
  set.add_route(EchoApp, :path => '/account/subscription', :method => 'post', :defaults => { :controller => 'account/subscription', :action => 'create' })
  set.add_route(EchoApp, :path => '/account/subscription/new', :method => 'get', :defaults => { :controller => 'account/subscription', :action => 'new' })
  set.add_route(EchoApp, :path => '/account/subscription/:id/edit', :method => 'get', :defaults => { :controller => 'account/subscription', :action => 'edit' })
  set.add_route(EchoApp, :path => '/account/subscription/:id', :method => 'get', :defaults => { :controller => 'account/subscription', :action => 'show' })
  set.add_route(EchoApp, :path => '/account/subscription/:id', :method => 'put', :defaults => { :controller => 'account/subscription', :action => 'update' })
  set.add_route(EchoApp, :path => '/account/subscription/:id', :method => 'delete', :defaults => { :controller => 'account/subscription', :action => 'destroy' })

  set.add_route(EchoApp, :path => '/account/credit', :method => 'get', :defaults => { :controller => 'account/credit', :action => 'index' })
  set.add_route(EchoApp, :path => '/account/credit', :method => 'post', :defaults => { :controller => 'account/credit', :action => 'create' })
  set.add_route(EchoApp, :path => '/account/credit/new', :method => 'get', :defaults => { :controller => 'account/credit', :action => 'new' })
  set.add_route(EchoApp, :path => '/account/credit/:id/edit', :method => 'get', :defaults => { :controller => 'account/credit', :action => 'edit' })
  set.add_route(EchoApp, :path => '/account/credit/:id', :method => 'get', :defaults => { :controller => 'account/credit', :action => 'show' })
  set.add_route(EchoApp, :path => '/account/credit/:id', :method => 'put', :defaults => { :controller => 'account/credit', :action => 'update' })
  set.add_route(EchoApp, :path => '/account/credit/:id', :method => 'delete', :defaults => { :controller => 'account/credit', :action => 'destroy' })

  set.add_route(EchoApp, :path => '/account/credit_card', :method => 'get', :defaults => { :controller => 'account/credit_card', :action => 'index' })
  set.add_route(EchoApp, :path => '/account/credit_card', :method => 'post', :defaults => { :controller => 'account/credit_card', :action => 'create' })
  set.add_route(EchoApp, :path => '/account/credit_card/new', :method => 'get', :defaults => { :controller => 'account/credit_card', :action => 'new' })
  set.add_route(EchoApp, :path => '/account/credit_card/:id/edit', :method => 'get', :defaults => { :controller => 'account/credit_card', :action => 'edit' })
  set.add_route(EchoApp, :path => '/account/credit_card/:id', :method => 'get', :defaults => { :controller => 'account/credit_card', :action => 'show' })
  set.add_route(EchoApp, :path => '/account/credit_card/:id', :method => 'put', :defaults => { :controller => 'account/credit_card', :action => 'update' })
  set.add_route(EchoApp, :path => '/account/credit_card/:id', :method => 'delete', :defaults => { :controller => 'account/credit_card', :action => 'destroy' })

  set.add_route(EchoApp, :path => 'foo', :defaults => { :controller => 'foo', :action => 'index' })
  set.add_route(EchoApp, :path => 'foo/bar', :defaults => { :controller => 'foo_bar', :action => 'index' })
  set.add_route(EchoApp, :path => '/baz', :defaults => { :controller => 'baz', :action => 'index' })

  set.add_route(EchoApp, :path => '/optional/index(.:format)', :defaults => { :controller => 'optional', :action => 'index' })

  set.add_route(EchoApp, :path => %r{^/regexp/foos?/(bar|baz)/([a-z0-9]+)$}, :capture_names => { :action => 1, :id => 2 }, :defaults => { :controller => 'foo' })
  set.add_route(EchoApp, :name => :complex_regexp, :path => %r{^/regexp/bar/([a-z]+)/([0-9]+)$}, :capture_names => [:action, :id], :defaults => { :controller => 'foo' })
  set.add_route(EchoApp, :name => :complex_regexp_fail, :path => %r{^/regexp/baz/[a-z]+/[0-9]+$}, :defaults => { :controller => 'foo' })

  set.add_route(EchoApp, :path => 'files/*files', :defaults => { :controller => 'files', :action => 'index' })

  set.add_route(Rack::Mount::PathPrefix.new(DefaultSet, '/prefix'), :path => %r{^/prefix/.*$})

  if Rack::Mount::Const::SUPPORTS_NAMED_CAPTURES
    regexp = eval('/^\/ruby19\/(?<action>[a-z]+)\/(?<id>[0-9]+)$/')
    set.add_route(EchoApp, :path => regexp, :defaults => { :controller => 'ruby19' })

    regexp = eval('/^\/ruby19\/index(\.(?<format>[a-z]+))?$/')
    set.add_route(EchoApp, :path => regexp, :defaults => { :controller => 'ruby19', :action => 'index' })

    regexp = eval('/^\/ruby19\/(?<action>[a-z]+)(\/(?<id>[0-9]+))?$/')
    set.add_route(EchoApp, :path => regexp, :defaults => { :controller => 'ruby19' })
  end

  set.add_route(EchoApp, :path => 'params_with_defaults(/:controller)', :defaults => { :controller => 'foo' })
  set.add_route(EchoApp, :path => 'default/:controller(/:action(/:id(.:format)))')
end
