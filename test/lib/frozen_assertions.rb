module FrozenAssertions
  def assert_frozen(*objs)
    if objs.length > 1
      objs.each { |e| assert_frozen(e) }
      return nil
    end

    obj = objs.pop
    case obj
    when Class, NilClass, Symbol, Integer
      return nil
    else
      assert obj.frozen?, "#{obj.inspect} was not frozen"
    end

    case obj
    when Array
      obj.each { |e| assert_frozen(e) }
    when Hash
      obj.each { |k, v| assert_frozen(k, v) }
    end

    obj.instance_variables.each do |ivar|
      assert_frozen(obj.instance_variable_get(ivar))
    end

    nil
  end
end
