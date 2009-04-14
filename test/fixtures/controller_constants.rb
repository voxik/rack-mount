module ControllerConstants
  def const_missing(name)
    if name.to_s =~ /Controller$/
      const_set(name, EchoApp)
    else
      super
    end
  end
end
