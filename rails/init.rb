require 'rack/mount'
require 'rack/mount/mappers/rails_classic'

ActionController::Routing::Routes = ::Rack::Mount::Mappers::RailsClassic::RouteSet.new
