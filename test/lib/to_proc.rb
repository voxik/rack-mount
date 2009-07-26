class Symbol
  def to_proc
    Proc.new { |*args| args.shift.__send__(self, *args) }
  end unless :to_proc.respond_to?(:to_proc)
end
