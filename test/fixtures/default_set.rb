DefaultSet = Rack::Mount::RouteSet.new do |set|
  set.add_route(EchoApp, :path => '/:controller(/:action(/:id(.:format)))')
end
