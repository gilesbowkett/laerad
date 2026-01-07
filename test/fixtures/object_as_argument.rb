def some_method(obj_as_argument)
  if some_condition? && argument&.query_method?
    obj_as_argument.field = value
  end
end