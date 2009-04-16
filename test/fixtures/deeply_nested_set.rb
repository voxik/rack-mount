set = Rack::Mount::NestedSet.new

('a'..'z').each do |level1|
  ('a'..'z').each do |level2|
    ('a'..'z').each do |level3|
      set[level1, level2, level3] = "#{level1}:#{level2}:#{level3}"
    end
    set[level1, level2] = "#{level1}:#{level2}:*"
  end
  set[level1] = "#{level1}:*:*"
end

DeeplyNestedSet = set
