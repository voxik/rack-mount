require 'action_controller'

module RouteSetTests
  Model = Struct.new(:to_param)

  Mapping = lambda { |map|
    map.namespace :admin do |admin|
      admin.resources :users
    end
    map.resources :people
    map.connect ':controller/:action/:id'
  }

  def setup
    ActionController::Routing.use_controllers! ['posts']
    @routes = ActionController::Routing::RouteSet.new
    @routes.draw(&Mapping)
    assert_loaded!
  end

  def assert_loaded!
    raise NotImplemented
  end

  def test_recognize_path
    assert_equal({:controller => 'admin/users', :action => 'index'}, @routes.recognize_path('/admin/users', :method => :get))
    assert_equal({:controller => 'admin/users', :action => 'create'}, @routes.recognize_path('/admin/users', :method => :post))
    assert_raise(ActionController::ActionControllerError) { @routes.recognize_path('/admin/users', :method => :put) }
    assert_raise(ActionController::ActionControllerError) { @routes.recognize_path('/admin/users', :method => :delete) }
    assert_equal({:controller => 'admin/users', :action => 'new'}, @routes.recognize_path('/admin/users/new', :method => :get))
    assert_raise(ActionController::ActionControllerError) { @routes.recognize_path('/admin/users/new', :method => :post) }
    assert_equal({:controller => 'admin/users', :action => 'show', :id => '1'}, @routes.recognize_path('/admin/users/1', :method => :get))
    assert_raise(ActionController::ActionControllerError) { @routes.recognize_path('/admin/users/1', :method => :post) }
    assert_equal({:controller => 'admin/users', :action => 'update', :id => '1'}, @routes.recognize_path('/admin/users/1', :method => :put))
    assert_equal({:controller => 'admin/users', :action => 'destroy', :id => '1'}, @routes.recognize_path('/admin/users/1', :method => :delete))
    assert_equal({:controller => 'admin/users', :action => 'edit', :id => '1'}, @routes.recognize_path('/admin/users/1/edit', :method => :get))
    assert_raise(ActionController::ActionControllerError) { @routes.recognize_path('/admin/users/1/edit', :method => :post) }

    assert_equal({:controller => 'people', :action => 'index'}, @routes.recognize_path('/people', :method => :get))
    assert_equal({:controller => 'people', :action => 'create'}, @routes.recognize_path('/people', :method => :post))
    assert_raise(ActionController::ActionControllerError) { @routes.recognize_path('/people', :method => :put) }
    assert_raise(ActionController::ActionControllerError) { @routes.recognize_path('/people', :method => :delete) }
    assert_equal({:controller => 'people', :action => 'new'}, @routes.recognize_path('/people/new', :method => :get))
    assert_raise(ActionController::ActionControllerError) { @routes.recognize_path('/people/new', :method => :post) }
    assert_equal({:controller => 'people', :action => 'show', :id => '1'}, @routes.recognize_path('/people/1', :method => :get))
    assert_raise(ActionController::ActionControllerError) { @routes.recognize_path('/people/1', :method => :post) }
    assert_equal({:controller => 'people', :action => 'update', :id => '1'}, @routes.recognize_path('/people/1', :method => :put))
    assert_equal({:controller => 'people', :action => 'destroy', :id => '1'}, @routes.recognize_path('/people/1', :method => :delete))
    assert_equal({:controller => 'people', :action => 'edit', :id => '1'}, @routes.recognize_path('/people/1/edit', :method => :get))
    assert_raise(ActionController::ActionControllerError) { @routes.recognize_path('/people/1/edit', :method => :post) }

    assert_equal({:controller => 'posts', :action => 'index'}, @routes.recognize_path('/posts', :method => :get))
    assert_equal({:controller => 'posts', :action => 'index'}, @routes.recognize_path('/posts/index', :method => :get))
    assert_equal({:controller => 'posts', :action => 'show'}, @routes.recognize_path('/posts/show', :method => :get))
    assert_equal({:controller => 'posts', :action => 'show', :id => '1'}, @routes.recognize_path('/posts/show/1', :method => :get))
    assert_equal({:controller => 'posts', :action => 'create'}, @routes.recognize_path('/posts/create', :method => :post))

    assert_raise(ActionController::RoutingError) { @routes.recognize_path('/', :method => :get) }
    assert_raise(ActionController::RoutingError) { @routes.recognize_path('/none', :method => :get) }
  end

  def test_generate
    assert_equal '/admin/users', @routes.generate(:use_route => 'admin_users')
    assert_equal '/admin/users', @routes.generate(:controller => 'admin/users')
    assert_equal '/admin/users', @routes.generate(:controller => 'admin/users', :action => 'index')
    assert_equal '/admin/users', @routes.generate({:action => 'index'}, {:controller => 'admin/users'})
    assert_equal '/admin/users', @routes.generate({:controller => 'users', :action => 'index'}, {:controller => 'admin/accounts'})
    assert_equal '/people', @routes.generate({:controller => '/people', :action => 'index'}, {:controller => 'admin/accounts'})

    # Passes on AC, but it doesn't seem correct
    # assert_equal '/admin/people', @routes.generate({:controller => 'people', :action => 'index'}, {:controller => 'admin/accounts'})

    assert_equal '/people', @routes.generate(:use_route => 'people')
    assert_equal '/people', @routes.generate(:use_route => 'people', :controller => 'people', :action => 'index')
    assert_equal '/people', @routes.generate({:use_route => 'people', :controller => 'people', :action => 'index'}, {:controller => 'people', :action => 'index'})
    assert_equal '/people', @routes.generate(:controller => 'people')
    assert_equal '/people', @routes.generate(:controller => 'people', :action => 'index')
    assert_equal '/people', @routes.generate({:action => 'index'}, {:controller => 'people'})
    assert_equal '/people', @routes.generate({:action => 'index'}, {:controller => 'people', :action => 'show', :id => '1'})
    assert_equal '/people/new', @routes.generate(:use_route => 'new_person')
    assert_equal '/people/new', @routes.generate(:controller => 'people', :action => 'new')
    assert_equal '/people/1', @routes.generate(:use_route => 'person', :id => '1')
    assert_equal '/people/1', @routes.generate(:controller => 'people', :action => 'show', :id => '1')
    assert_equal '/people/1', @routes.generate(:controller => 'people', :action => 'show', :id => 1)
    assert_equal '/people/1', @routes.generate(:controller => 'people', :action => 'show', :id => Model.new('1'))
    assert_equal '/people/1', @routes.generate({:action => 'show', :id => '1'}, {:controller => 'people', :action => 'index'})
    assert_equal '/people/1/edit', @routes.generate(:controller => 'people', :action => 'edit', :id => '1')
    assert_equal '/people/1/edit', @routes.generate(:use_route => 'edit_person', :id => '1')

    assert_equal '/posts/show/1', @routes.generate(:controller => 'posts', :action => 'show', :id => '1')
    assert_equal '/posts', @routes.generate(:controller => 'posts')
    assert_equal '/posts', @routes.generate(:controller => 'posts', :action => 'index')
    assert_equal '/posts', @routes.generate({:controller => 'posts'}, {:controller => 'posts', :action => 'index'})

    assert_raise(ActionController::RoutingError) { @routes.generate({:action => 'index'}) }
  end

  def test_extras
    assert_equal [], @routes.extra_keys(:controller => 'people')
    assert_equal [:foo], @routes.extra_keys(:controller => 'people', :foo => 'bar')
    assert_equal [], @routes.extra_keys(:controller => 'people', :action => 'index')
    assert_equal [:foo], @routes.extra_keys(:controller => 'people', :action => 'index', :foo => 'bar')
    assert_equal [], @routes.extra_keys(:controller => 'people', :action => 'new')
    assert_equal [:foo], @routes.extra_keys(:controller => 'people', :action => 'new', :foo => 'bar')
    assert_equal [], @routes.extra_keys(:controller => 'people', :action => 'show', :id => '1')
    assert_equal [:bar, :foo], @routes.extra_keys(:controller => 'people', :action => 'show', :id => '1', :foo => '2', :bar => '3').sort { |a, b| a.to_s <=> b.to_s }

    assert_equal [], @routes.extra_keys(:controller => 'posts', :action => 'show', :id => '1')
    assert_equal [:bar, :foo], @routes.extra_keys(:controller => 'posts', :action => 'show', :id => '1', :foo => '2', :bar => '3').sort { |a, b| a.to_s <=> b.to_s }
    assert_equal [], @routes.extra_keys(:controller => 'posts', :action => 'index')
    assert_equal [:foo], @routes.extra_keys(:controller => 'posts', :action => 'index', :foo => 'bar')
  end

  private
    def assert_raise(e)
      result = yield
      flunk "Did not raise #{e}, but returned #{result.inspect}"
    rescue e
      assert true
    end
end
