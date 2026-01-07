def some_method(obj_as_argument)
  if some_condition? && obj_as_argument&.query_method?
    obj_as_argument.field = value
  end
end