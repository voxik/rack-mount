NestedSetB = Rack::Mount::RouteSet.new do |set|
  set.add_route(EchoApp, { :path_info => '/pass' })
end
