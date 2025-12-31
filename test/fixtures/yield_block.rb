def with_yield(&block)
  yield
end

def with_explicit(&block)
  block.call
  block.call
end

def unused_block_param(&block)
  puts "nothing"
end
