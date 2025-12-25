# frozen_string_literal: true

require "test_helper"

class TestResult < Minitest::Test
  def test_add_variable_violation
    result = Laerad::Result.new(file: "test.rb")
    result.add_variable_violation(name: "x", line: 5, count: 1)

    assert_equal 1, result.variable_violations.size
    assert_equal({name: "x", line: 5, count: 1}, result.variable_violations.first)
  end

  def test_violations_returns_true_when_violations_exist
    result = Laerad::Result.new(file: "test.rb")
    refute result.violations?

    result.add_variable_violation(name: "x", line: 1, count: 1)
    assert result.violations?
  end

  def test_merge_combines_results
    result1 = Laerad::Result.new(file: "file1.rb")
    result1.add_variable_violation(name: "x", line: 1, count: 1)

    result2 = Laerad::Result.new(file: "file2.rb")
    result2.add_variable_violation(name: "y", line: 5, count: 1)

    merged = Laerad::Result.merge(result1, result2)

    assert_equal 2, merged.variable_violations.size
    assert_equal "file1.rb", merged.variable_violations.first[:file]
    assert_equal "file2.rb", merged.variable_violations.last[:file]
  end

  def test_format_output
    result = Laerad::Result.new(file: "test.rb")
    result.add_variable_violation(name: "x", line: 5, count: 1)

    output = result.format_output

    assert_includes output, "File"
    assert_includes output, "Line"
    assert_includes output, "Variable"
    assert_includes output, "Uses"
    assert_includes output, "test.rb"
    assert_includes output, "5"
    assert_includes output, "x"
    assert_includes output, "1"
  end

  def test_format_output_short
    result = Laerad::Result.new(file: "test.rb")
    result.add_variable_violation(name: "x", line: 5, count: 1)
    result.add_variable_violation(name: "y", line: 10, count: 1)

    output = result.format_output(short: true)

    assert_equal "test.rb:5\ntest.rb:10", output
  end
end
