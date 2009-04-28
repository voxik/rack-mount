Gem::Specification.new do |s|
  s.name     = 'rack-mount'
  s.version  = '0.0.1'
  s.date     = '2009-04-28'
  s.summary  = 'Stackable dynamic tree based Rack router'
  s.description = s.summary
  s.email    = 'josh@joshpeek.com'
  s.homepage = 'http://github.com/josh/rack-mount'
  s.has_rdoc = true
  s.authors  = ["Joshua Peek"]
  s.files    = Dir["lib/**/*", "rails/init.rb"]
  s.extra_rdoc_files = %w[README.rdoc MIT-LICENSE]
  s.require_paths = %w[lib]
  s.add_dependency 'rack', '> 1.0.0'
end
