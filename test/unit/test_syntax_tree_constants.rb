# frozen_string_literal: true

require "test_helper"

class TestSyntaxTreeConstants < Minitest::Test
  def test_all_referenced_syntax_tree_constants_exist
    lib_path = File.expand_path("../../lib", __dir__)
    ruby_files = Dir.glob("#{lib_path}/**/*.rb")

    constants = ruby_files.flat_map do |file|
      File.read(file).scan(/SyntaxTree::(\w+)/).flatten
    end.uniq

    assert constants.any?, "Should find at least one SyntaxTree constant reference"

    constants.each do |const_name|
      begin
        SyntaxTree.const_get(const_name)
        pass
      rescue NameError
        flunk "SyntaxTree::#{const_name} does not exist"
      end
    end
  end
end
