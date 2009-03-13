set = Rack::Mount::RouteSet.new

set.add_route(EchoApp, :path => "/people", :method => "get", :defaults => { :controller => "people", :action => "index" })
set.add_route(EchoApp, :path => "/people", :method => "post", :defaults => { :controller => "people", :action => "create" })
set.add_route(EchoApp, :path => "/people/new", :method => "get", :defaults => { :controller => "people", :action => "new" })
set.add_route(EchoApp, :path => "/people/:id/edit", :method => "get", :defaults => { :controller => "people", :action => "edit" })
set.add_route(EchoApp, :path => "/people/:id", :method => "get", :defaults => { :controller => "people", :action => "show" })
set.add_route(EchoApp, :path => "/people/:id", :method => "put", :defaults => { :controller => "people", :action => "update" })
set.add_route(EchoApp, :path => "/people/:id", :method => "delete", :defaults => { :controller => "people", :action => "destroy" })

set.add_route(EchoApp, :path => "/", :defaults => { :controller => "homepage" })

set.add_route(EchoApp, :path => "/geocode/:postalcode", :defaults => { :controller => "geocode", :action => "show" }, :requirements => { :postalcode => /\d{5}(-\d{4})?/ })
set.add_route(EchoApp, :path => "/geocode2/:postalcode", :defaults => { :controller => "geocode", :action => "show" }, :requirements => { :postalcode => /\d{5}(-\d{4})?/ })

set.add_route(EchoApp, :path => "/login", :method => "get", :defaults => { :controller => "sessions", :action => "new" })
set.add_route(EchoApp, :path => "/login", :method => "post", :defaults => { :controller => "sessions", :action => "create" })
set.add_route(EchoApp, :path => "/logout", :method => "delete", :defaults => { :controller => "sessions", :action => "destroy" })

set.add_route(EchoApp, :path => "/global/:action", :defaults => { :controller => "global" })
set.add_route(EchoApp, :path => "/global/export", :defaults => { :controller => "global", :action => "export" })
set.add_route(EchoApp, :path => "/global/hide_notice", :defaults => { :controller => "global", :action => "hide_notice" })
set.add_route(EchoApp, :path => "/export/:id/:file", :defaults => { :controller => "global", :action => "export" }, :requirements => { :file => /.*/ })

set.add_route(EchoApp, :path => "foo", :defaults => { :controller => "foo", :action => "index" })
set.add_route(EchoApp, :path => "foo/bar", :defaults => { :controller => "foo_bar", :action => "index" })
set.add_route(EchoApp, :path => "/baz", :defaults => { :controller => "baz", :action => "index" })

set.add_route(EchoApp, :path => "files/*files", :defaults => { :controller => "files", :action => "index" })

set.add_route(EchoApp, :path => ":controller/:action/:id")
set.add_route(EchoApp, :path => ":controller/:action/:id.:format")

set.freeze

BasicSet = set
