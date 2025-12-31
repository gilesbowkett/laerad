class Parent
  def method(a, b, c = "default")
  end
end

class Child < Parent
  def method(a, b, c = "default")
    super
  end
end

class ExplicitChild < Parent
  def method(a, b, c = "default")
    super(a)
  end
end
