class Array
  def all_permutations
    a = []
    (0..size).each { |n| _each_permutation(n) { |e| a << e } }
    a
  end

  def _each_permutation(n)
    if size < n or n < 0
    elsif n == 0
      yield([])
    else
      self[1..-1]._each_permutation(n - 1) do |x|
        (0...n).each do |i|
          yield(x[0...i] + [first] + x[i..-1])
        end
      end
      self[1..-1]._each_permutation(n) do |x|
        yield(x)
      end
    end
  end
  protected :_each_permutation
end
