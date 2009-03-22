require 'rack/mount'
require 'rack/mount/mappers/rails_classic'

class ::Rack::Mount::RouteSet
  def add_configuration_file(path)
    load(path)
  end

  def load!
  end
  alias reload! load!

  def reload
  end
end

ActionController::Routing::Routes = ::Rack::Mount::RouteSet.new
