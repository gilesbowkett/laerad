# frozen_string_literal: true

require "test_helper"

class TestScope < Minitest::Test
  def setup
    @scope = Laerad::Scope.new
  end

  def test_variable_usage_tracking
    @scope.register_variable_def("x", 1)
    @scope.register_variable_ref("x")
    @scope.register_variable_ref("x")

    assert_equal 3, @scope.variable_count("x")
    assert_equal [1], @scope.variable_def_lines["x"]
  end

  def test_single_use_variables
    @scope.register_variable_def("multi_use", 1)
    @scope.register_variable_ref("multi_use")
    @scope.register_variable_ref("multi_use")
    @scope.register_variable_def("single_use", 2)
    @scope.register_variable_ref("single_use")

    assert_includes @scope.single_use_variables, "single_use"
    refute_includes @scope.single_use_variables, "multi_use"
  end

  def test_variable_definition_line
    @scope.register_variable_def("x", 10)

    assert_equal 10, @scope.variable_definition_line("x")
  end
end
