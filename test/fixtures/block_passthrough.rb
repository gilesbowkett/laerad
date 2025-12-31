def pass_through(&block)
  other_method(&block)
end

def unused_block(&block)
  other_method
end
