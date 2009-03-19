module ControllerConstants
  def const_missing(name)
    if name.to_s =~ /Controller$/
      EchoApp
    else
      super
    end
  end
end
