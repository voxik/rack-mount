require 'rack/mount'
require 'rack/mount/mappers/rails_classic'

ActionController::Routing::Routes = ::Rack::Mount::RouteSet.new
