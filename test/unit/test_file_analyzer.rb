# frozen_string_literal: true

require "test_helper"

class TestFileAnalyzer < Minitest::Test
  def fixture_path(name)
    File.expand_path("../fixtures/#{name}", __dir__)
  end

  def test_simple_variable_usage
    result = Laerad::FileAnalyzer.analyze(fixture_path("simple_variable.rb"))

    refute result.variable_violations.any? { |v| v[:name] == "x" }
  end

  def test_unused_variable
    result = Laerad::FileAnalyzer.analyze(fixture_path("unused_variable.rb"))

    assert result.variable_violations.any? { |v| v[:name] == "x" }
  end

  def test_multi_use_variable
    result = Laerad::FileAnalyzer.analyze(fixture_path("multi_use_variable.rb"))

    refute result.variable_violations.any? { |v| v[:name] == "x" }
  end

  def test_simple_method_usage
    result = Laerad::FileAnalyzer.analyze(fixture_path("simple_method.rb"))

    refute result.method_violations.any? { |v| v[:name] == "helper" }
  end

  def test_unused_method
    result = Laerad::FileAnalyzer.analyze(fixture_path("unused_method.rb"))

    assert result.method_violations.any? { |v| v[:name] == "helper" }
  end

  def test_multi_use_method
    result = Laerad::FileAnalyzer.analyze(fixture_path("multi_use_method.rb"))

    refute result.method_violations.any? { |v| v[:name] == "helper" }
  end

  def test_dynamic_send_ignores_method_rule
    result = Laerad::FileAnalyzer.analyze(fixture_path("dynamic_send.rb"))

    refute result.method_violations.any? { |v| v[:name] == "foo" }
  end

  def test_define_method_marks_dynamic
    result = Laerad::FileAnalyzer.analyze(fixture_path("dsl_define_method.rb"))

    refute result.method_violations.any?
  end

  def test_nested_scopes_variable_usage
    result = Laerad::FileAnalyzer.analyze(fixture_path("nested_scopes.rb"))

    # x is defined in outer scope and used in block, but they are separate scopes
    # so x in the outer method is only defined once (single use)
    # This tests that nested scopes work correctly
    assert result.violations?
  end

  def test_parameters_count_as_definition
    # Create a temporary file to test parameter handling
    require "tempfile"
    file = Tempfile.new(["test", ".rb"])
    file.write("def foo(x)\n  x\nend\n")
    file.close

    result = Laerad::FileAnalyzer.analyze(file.path)

    refute result.variable_violations.any? { |v| v[:name] == "x" }
  ensure
    file&.unlink
  end

  def test_rescue_binding
    require "tempfile"
    file = Tempfile.new(["test", ".rb"])
    file.write("begin\n  raise\nrescue => e\n  puts e\nend\n")
    file.close

    result = Laerad::FileAnalyzer.analyze(file.path)

    refute result.variable_violations.any? { |v| v[:name] == "e" }
  ensure
    file&.unlink
  end
end
