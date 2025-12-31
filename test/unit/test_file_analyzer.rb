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

  def test_block_closure_references_outer_variable
    result = Laerad::FileAnalyzer.analyze(fixture_path("block_closure.rb"))

    refute result.variable_violations.any? { |v| v[:name] == "mapping" }
  end

  def test_block_parameter_shadows_outer_variable
    result = Laerad::FileAnalyzer.analyze(fixture_path("block_shadowing.rb"))

    refute result.variable_violations.any? { |v| v[:name] == "x" }
  end

  def test_nested_block_references_outer_variable
    result = Laerad::FileAnalyzer.analyze(fixture_path("nested_block_closure.rb"))

    refute result.variable_violations.any? { |v| v[:name] == "total" }
  end

  def test_method_chain_counts_base_variable
    result = Laerad::FileAnalyzer.analyze(fixture_path("method_chain.rb"))

    refute result.variable_violations.any? { |v| v[:name] == "user" }
  end

  def test_underscore_prefixed_variables_ignored
    result = Laerad::FileAnalyzer.analyze(fixture_path("underscore_prefix.rb"))

    refute result.variable_violations.any? { |v| v[:name] == "_unused" }
    refute result.variable_violations.any? { |v| v[:name] == "_first" }
  end

  def test_numbered_block_params_ignored
    result = Laerad::FileAnalyzer.analyze(fixture_path("numbered_params.rb"))

    refute result.variable_violations.any? { |v| v[:name] == "_1" }
  end

  def test_keyword_args_used
    result = Laerad::FileAnalyzer.analyze(fixture_path("keyword_args.rb"))

    refute result.variable_violations.any? { |v| v[:name] == "foo" }
    assert result.variable_violations.any? { |v| v[:name] == "bar" }
  end

  def test_block_passthrough
    result = Laerad::FileAnalyzer.analyze(fixture_path("block_passthrough.rb"))

    passthrough = result.variable_violations.find { |v| v[:name] == "block" && v[:line] == 1 }
    unused = result.variable_violations.find { |v| v[:name] == "block" && v[:line] == 5 }

    assert_equal 2, passthrough[:count], "passthrough block should have 2 appearances"
    assert_equal 1, unused[:count], "unused block should have 1 appearance"
  end

  def test_yield_implicit_block_use
    result = Laerad::FileAnalyzer.analyze(fixture_path("yield_block.rb"))

    refute result.variable_violations.any? { |v| v[:name] == "block" && v[:line] == 1 }
    refute result.variable_violations.any? { |v| v[:name] == "block" && v[:line] == 5 }
    assert result.variable_violations.any? { |v| v[:name] == "block" && v[:line] == 10 }
  end

  def test_super_implicit_params
    result = Laerad::FileAnalyzer.analyze(fixture_path("super_implicit.rb"))

    # Child uses bare super - all params implicitly used, should not be flagged
    refute result.variable_violations.any? { |v| v[:name] == "a" && v[:line] == 7 }
    refute result.variable_violations.any? { |v| v[:name] == "b" && v[:line] == 7 }
    refute result.variable_violations.any? { |v| v[:name] == "c" && v[:line] == 7 }

    # ExplicitChild uses super(a) - b and c are genuinely unused
    assert result.variable_violations.any? { |v| v[:name] == "b" && v[:line] == 13 }
    assert result.variable_violations.any? { |v| v[:name] == "c" && v[:line] == 13 }
  end
end
