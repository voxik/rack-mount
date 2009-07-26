class Rack::Mount::Multimap
  def average_height
    lengths = containers_with_default.map { |e| e.length }
    lengths.inject(0) { |sum, len| sum += len }.to_f / lengths.size
  end
end
