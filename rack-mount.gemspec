Gem::Specification.new do |s|
  s.name      = 'rack-mount'
  s.version   = '0.7.0'
  s.date      = '2011-03-23'

  s.homepage    = "https://github.com/josh/rack-mount"
  s.summary     = "Stackable dynamic tree based Rack router"
  s.description = <<-EOS
    A stackable dynamic tree based Rack router.
  EOS

  s.files = [
   "lib/rack/mount.rb",
   "lib/rack/mount/analysis/frequency.rb",
   "lib/rack/mount/analysis/histogram.rb",
   "lib/rack/mount/analysis/splitting.rb",
   "lib/rack/mount/code_generation.rb",
   "lib/rack/mount/generatable_regexp.rb",
   "lib/rack/mount/multimap.rb",
   "lib/rack/mount/prefix.rb",
   "lib/rack/mount/regexp_with_named_groups.rb",
   "lib/rack/mount/route.rb",
   "lib/rack/mount/route_set.rb",
   "lib/rack/mount/strexp.rb",
   "lib/rack/mount/strexp/parser.rb",
   "lib/rack/mount/strexp/parser.y",
   "lib/rack/mount/strexp/tokenizer.rb",
   "lib/rack/mount/strexp/tokenizer.rex",
   "lib/rack/mount/utils.rb",
   "lib/rack/mount/vendor/multimap/multimap.rb",
   "lib/rack/mount/vendor/multimap/multiset.rb",
   "lib/rack/mount/vendor/multimap/nested_multimap.rb",
   "lib/rack/mount/vendor/regin/regin.rb",
   "lib/rack/mount/vendor/regin/regin/alternation.rb",
   "lib/rack/mount/vendor/regin/regin/anchor.rb",
   "lib/rack/mount/vendor/regin/regin/atom.rb",
   "lib/rack/mount/vendor/regin/regin/character.rb",
   "lib/rack/mount/vendor/regin/regin/character_class.rb",
   "lib/rack/mount/vendor/regin/regin/collection.rb",
   "lib/rack/mount/vendor/regin/regin/expression.rb",
   "lib/rack/mount/vendor/regin/regin/group.rb",
   "lib/rack/mount/vendor/regin/regin/options.rb",
   "lib/rack/mount/vendor/regin/regin/parser.rb",
   "lib/rack/mount/vendor/regin/regin/tokenizer.rb",
   "lib/rack/mount/vendor/regin/regin/version.rb",
   "lib/rack/mount/version.rb",
   "LICENSE",
   "README.rdoc"
  ]

  s.add_dependency 'rack', '>=1.0.0'
  s.add_development_dependency 'racc'
  s.add_development_dependency 'rexical'

  s.authors           = ["Joshua Peek"]
  s.email             = "josh@joshpeek.com"
  s.rubyforge_project = 'rack-mount'
end
