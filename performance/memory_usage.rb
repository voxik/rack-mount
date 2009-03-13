require 'rubygems'
require 'rack/mount'
require 'fixtures'
require 'ruby-prof'

Env = {
  "REQUEST_METHOD" => "GET",
  "PATH_INFO" => "/foo"
}

routes = BasicSet
routes.call(Env.dup)
env = Env.dup

RubyProf.measure_mode = RubyProf::ALLOCATIONS

result = RubyProf.profile do
  routes.call(env)
end

printer = RubyProf::FlatPrinter.new(result)
printer.print(STDOUT, 0)
