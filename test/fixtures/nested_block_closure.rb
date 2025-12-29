def process
  total = 0
  [[1, 2], [3, 4]].each do |arr|
    arr.each { |n| total += n }
  end
  total
end
