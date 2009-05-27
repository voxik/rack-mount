begin
  require 'fuzzy_nested_multimap'
rescue LoadError
  $: << File.expand_path(File.join(File.dirname(__FILE__), 'vendor/multimap'))
  require 'fuzzy_nested_multimap'
end

Rack::Mount::Multimap = FuzzyNestedMultimap
