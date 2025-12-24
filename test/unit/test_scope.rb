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

  def test_method_usage_tracking
    @scope.register_method_def("foo", 5)
    @scope.register_method_call("foo")
    @scope.register_method_call("foo")

    assert_equal 3, @scope.method_count("foo")
    assert_equal [5], @scope.method_def_lines["foo"]
  end

  def test_dynamic_flag
    refute @scope.dynamic?

    @scope.mark_dynamic!

    assert @scope.dynamic?
  end

  def test_single_use_variables
    @scope.register_variable_def("used", 1)
    @scope.register_variable_ref("used")
    @scope.register_variable_def("unused", 2)

    assert_includes @scope.single_use_variables, "unused"
    refute_includes @scope.single_use_variables, "used"
  end

  def test_single_use_methods
    @scope.register_method_def("used", 1)
    @scope.register_method_call("used")
    @scope.register_method_def("unused", 2)

    assert_includes @scope.single_use_methods, "unused"
    refute_includes @scope.single_use_methods, "used"
  end

  def test_single_use_methods_skipped_when_dynamic
    @scope.register_method_def("unused", 1)
    @scope.mark_dynamic!

    assert_empty @scope.single_use_methods
  end

  def test_variable_definition_line
    @scope.register_variable_def("x", 10)

    assert_equal 10, @scope.variable_definition_line("x")
  end

  def test_method_definition_line
    @scope.register_method_def("foo", 20)

    assert_equal 20, @scope.method_definition_line("foo")
  end
end
