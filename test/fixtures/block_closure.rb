def process
  mapping = { "a" => 1, "b" => 2 }
  ["a", "b"].filter_map do |k|
    next if mapping[k] == 1
    mapping[k] * 2
  end
end
