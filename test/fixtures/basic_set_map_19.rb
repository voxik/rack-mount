BasicSetMap = Proc.new do |set|
  set.add_route(EchoApp, { :path => '/people', :method => 'GET' }, { :controller => 'people', :action => 'index' })
  set.add_route(EchoApp, { :path => '/people', :method => 'POST' }, { :controller => 'people', :action => 'create' })
  set.add_route(EchoApp, { :path => '/people/new', :method => 'GET' }, { :controller => 'people', :action => 'new' })
  set.add_route(EchoApp, { :path => %r{^/people/(?<id>[a-z0-9]+)/edit$}, :method => 'GET' }, { :controller => 'people', :action => 'edit' })
  set.add_route(EchoApp, { :path => %r{^/people/(?<id>[a-z0-9]+)$}, :method => 'GET' }, { :controller => 'people', :action => 'show' })
  set.add_route(EchoApp, { :path => %r{^/people/(?<id>[a-z0-9]+)$}, :method => 'PUT' }, { :controller => 'people', :action => 'update' })
  set.add_route(EchoApp, { :path => %r{^/people/(?<id>[a-z0-9]+)$}, :method => 'DELETE' }, { :controller => 'people', :action => 'destroy' })

  set.add_route(EchoApp, { :path => '/' }, { :controller => 'homepage' })

  set.add_route(EchoApp, { :path => %r{^/geocode/(?<postalcode>\d{5}(-\d{4})?)$} }, { :controller => 'geocode', :action => 'show' }, :geocode)
  set.add_route(EchoApp, { :path => %r{^/geocode2/(?<postalcode>\d{5}(-\d{4})?)$} }, { :controller => 'geocode', :action => 'show' }, :geocode2)

  set.add_route(EchoApp, { :path => '/login', :method => 'GET' }, { :controller => 'sessions', :action => 'new' }, :login)
  set.add_route(EchoApp, { :path => '/login', :method => 'POST' }, { :controller => 'sessions', :action => 'create' })
  set.add_route(EchoApp, { :path => '/logout', :method => 'DELETE' }, { :controller => 'sessions', :action => 'destroy' }, :logout)

  set.add_route(EchoApp, { :path => %r{^/global/(?<action>[a-z0-9]+)$} }, { :controller => 'global' })
  set.add_route(EchoApp, { :path => '/global/export' }, { :controller => 'global', :action => 'export' }, :export_request)
  set.add_route(EchoApp, { :path => '/global/hide_notice' }, { :controller => 'global', :action => 'hide_notice' }, :hide_notice)
  set.add_route(EchoApp, { :path => %r{^/export/(?<id>[a-z0-9]+)/(?<file>.*)$} }, { :controller => 'global', :action => 'export' }, :export_download)

  set.add_route(EchoApp, { :path => '/account/subscription', :method => 'GET' }, { :controller => 'account/subscription', :action => 'index' })
  set.add_route(EchoApp, { :path => '/account/subscription', :method => 'POST' }, { :controller => 'account/subscription', :action => 'create' })
  set.add_route(EchoApp, { :path => '/account/subscription/new', :method => 'GET' }, { :controller => 'account/subscription', :action => 'new' })
  set.add_route(EchoApp, { :path => %r{^/account/subscription/(?<id>[a-z0-9]+)/edit$}, :method => 'GET' }, { :controller => 'account/subscription', :action => 'edit' })
  set.add_route(EchoApp, { :path => %r{^/account/subscription/(?<id>[a-z0-9]+)$}, :method => 'GET' }, { :controller => 'account/subscription', :action => 'show' })
  set.add_route(EchoApp, { :path => %r{^/account/subscription/(?<id>[a-z0-9]+)$}, :method => 'PUT' }, { :controller => 'account/subscription', :action => 'update' })
  set.add_route(EchoApp, { :path => %r{^/account/subscription/(?<id>[a-z0-9]+)$}, :method => 'DELETE' }, { :controller => 'account/subscription', :action => 'destroy' })

  set.add_route(EchoApp, { :path => '/account/credit', :method => 'GET' }, { :controller => 'account/credit', :action => 'index' })
  set.add_route(EchoApp, { :path => '/account/credit', :method => 'POST' }, { :controller => 'account/credit', :action => 'create' })
  set.add_route(EchoApp, { :path => '/account/credit/new', :method => 'GET' }, { :controller => 'account/credit', :action => 'new' })
  set.add_route(EchoApp, { :path => %r{^/account/credit/(?<id>[a-z0-9]+)/edit$}, :method => 'GET' }, { :controller => 'account/credit', :action => 'edit' })
  set.add_route(EchoApp, { :path => %r{^/account/credit/(?<id>[a-z0-9]+)$}, :method => 'GET' }, { :controller => 'account/credit', :action => 'show' })
  set.add_route(EchoApp, { :path => %r{^/account/credit/(?<id>[a-z0-9]+)$}, :method => 'PUT' }, { :controller => 'account/credit', :action => 'update' })
  set.add_route(EchoApp, { :path => %r{^/account/credit/(?<id>[a-z0-9]+)$}, :method => 'DELETE' }, { :controller => 'account/credit', :action => 'destroy' })

  set.add_route(EchoApp, { :path => '/account/credit_card', :method => 'GET' }, { :controller => 'account/credit_card', :action => 'index' })
  set.add_route(EchoApp, { :path => '/account/credit_card', :method => 'POST' }, { :controller => 'account/credit_card', :action => 'create' })
  set.add_route(EchoApp, { :path => '/account/credit_card/new', :method => 'GET' }, { :controller => 'account/credit_card', :action => 'new' })
  set.add_route(EchoApp, { :path => %r{^/account/credit_card/(?<id>[a-z0-9]+)/edit$}, :method => 'GET' }, { :controller => 'account/credit_card', :action => 'edit' })
  set.add_route(EchoApp, { :path => %r{^/account/credit_card/(?<id>[a-z0-9]+)$}, :method => 'GET' }, { :controller => 'account/credit_card', :action => 'show' })
  set.add_route(EchoApp, { :path => %r{^/account/credit_card/(?<id>[a-z0-9]+)$}, :method => 'PUT' }, { :controller => 'account/credit_card', :action => 'update' })
  set.add_route(EchoApp, { :path => %r{^/account/credit_card/(?<id>[a-z0-9]+)$}, :method => 'DELETE' }, { :controller => 'account/credit_card', :action => 'destroy' })

  set.add_route(EchoApp, { :path => 'foo' }, { :controller => 'foo', :action => 'index' })
  set.add_route(EchoApp, { :path => 'foo/bar' }, { :controller => 'foo_bar', :action => 'index' })
  set.add_route(EchoApp, { :path => '/baz' }, { :controller => 'baz', :action => 'index' })

  set.add_route(EchoApp, { :path => '/slashes/trailing/' }, { :controller => 'slash', :action => 'trailing' })
  set.add_route(EchoApp, { :path => '//slashes/repeated' }, { :controller => 'slash', :action => 'repeated' })

  set.add_route(EchoApp, { :path => '/ssl', :scheme => 'http' }, { :controller => 'ssl', :action => 'nonssl' })
  set.add_route(EchoApp, { :path => '/ssl', :scheme => 'https' }, { :controller => 'ssl', :action => 'ssl' })
  set.add_route(EchoApp, { :path => '/method', :method => /get|post/i }, { :controller => 'method', :action => 'index' })

  set.add_route(EchoApp, { :path => %r{^/optional/index(\.(?<format>[a-z]+))?$} }, { :controller => 'optional', :action => 'index' })

  set.add_route(EchoApp, { :path => %r{^/regexp/foos?/(?<action>bar|baz)/(?<id>[a-z0-9]+)$} }, { :controller => 'foo' })
  set.add_route(EchoApp, { :path => %r{^/regexp/bar/(?<action>[a-z]+)/(?<id>[0-9]+)$} }, { :controller => 'foo' }, :complex_regexp)
  set.add_route(EchoApp, { :path => %r{^/regexp/baz/[a-z]+/[0-9]+$} }, { :controller => 'foo' }, :complex_regexp_fail)

  set.add_route(EchoApp, { :path => %r{^/files/(?<files>.*)$} }, { :controller => 'files', :action => 'index' })

  set.add_route(Rack::Mount::PathPrefix.new(DefaultSet, '/prefix'), :path => %r{^/prefix/.*$})

  set.add_route(EchoApp, { :path => %r{^/params_with_defaults(/(?<controller>[a-z0-9]+))?$} }, { :controller => 'foo' })
  set.add_route(EchoApp, :path => %r{^/default/(?<controller>[a-z0-9]+)(/(?<action>[a-z0-9]+)(/(?<id>[a-z0-9]+)(\.(?<format>[a-z]+))?)?)?$})
  set.add_route(EchoApp, { :method => 'DELETE' }, { :controller => 'global', :action => 'destroy' })
end
