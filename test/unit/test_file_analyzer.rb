# frozen_string_literal: true

require "test_helper"

class TestFileAnalyzer < Minitest::Test
  def fixture_path(name)
    File.expand_path("../fixtures/#{name}", __dir__)
  end

  def test_single_use_variable
    result = Laerad::FileAnalyzer.analyze(fixture_path("single_use_variable.rb"))

    assert result.variable_violations.any? { |v| v[:name] == "x" }
  end

  def test_unused_variable
    result = Laerad::FileAnalyzer.analyze(fixture_path("unused_variable.rb"))

    assert result.variable_violations.any? { |v| v[:name] == "x" }
  end

  def test_multi_use_variable
    result = Laerad::FileAnalyzer.analyze(fixture_path("multi_use_variable.rb"))

    refute result.variable_violations.any? { |v| v[:name] == "x" }
  end

  def test_nested_scopes_variable_usage
    result = Laerad::FileAnalyzer.analyze(fixture_path("nested_scopes.rb"))

    # x is defined in outer scope and used in block, but they are separate scopes
    # so x in the outer method is only defined once (single use)
    # This tests that nested scopes work correctly
    assert result.violations?
  end

  def test_multi_use_parameter
    result = Laerad::FileAnalyzer.analyze(fixture_path("multi_use_parameter.rb"))

    refute result.variable_violations.any? { |v| v[:name] == "x" }
  end

  def test_multi_use_rescue_binding
    result = Laerad::FileAnalyzer.analyze(fixture_path("multi_use_rescue_binding.rb"))

    refute result.variable_violations.any? { |v| v[:name] == "e" }
  end
end
