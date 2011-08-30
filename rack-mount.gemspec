Gem::Specification.new do |s|
  s.name    = 'rack-mount'
  s.version = '0.8.3'

  s.homepage    = "https://github.com/josh/rack-mount"
  s.summary     = "Stackable dynamic tree based Rack router"
  s.description = <<-EOS
    A stackable dynamic tree based Rack router.
  EOS

  s.files = Dir["README.rdoc", "LICENSE", "lib/**/*.rb"]

  s.add_dependency 'rack', '>=1.0.0'
  s.add_development_dependency 'racc'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rexical'

  s.authors = ["Joshua Peek"]
  s.email   = "josh@joshpeek.com"
end
