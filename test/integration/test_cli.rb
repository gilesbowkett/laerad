# frozen_string_literal: true

require "test_helper"
require "open3"

class TestCLI < Minitest::Test
  def bin_path
    File.expand_path("../../bin/laerad", __dir__)
  end

  def fixture_path(name)
    File.expand_path("../fixtures/#{name}", __dir__)
  end

  def run_cli(*args)
    env = {"BUNDLE_GEMFILE" => File.expand_path("../../Gemfile", __dir__)}
    cmd = ["bundle", "exec", "ruby", bin_path, *args]
    Open3.capture3(env, *cmd)
  end

  def test_scan_file_with_no_violations
    stdout, _stderr, status = run_cli("scan", fixture_path("simple_variable.rb"))

    assert_equal 0, status.exitstatus
    assert_includes stdout, "No violations found"
  end

  def test_scan_file_with_violations
    stdout, _stderr, status = run_cli("scan", fixture_path("unused_variable.rb"))

    assert_equal 1, status.exitstatus
    assert_includes stdout, "Single-use variables:"
    assert_includes stdout, "x"
  end

  def test_scan_directory
    _stdout, _stderr, status = run_cli("scan", File.expand_path("../fixtures", __dir__))

    # The fixtures directory has files with violations
    assert_equal 1, status.exitstatus
  end

  def test_version_command
    stdout, _stderr, status = run_cli("version")

    assert_equal 0, status.exitstatus
    assert_includes stdout, "laerad"
    assert_includes stdout, Laerad::VERSION
  end

  def test_methods_only_flag
    stdout, _stderr, status = run_cli("scan", "--methods-only", fixture_path("unused_variable.rb"))

    assert_equal 1, status.exitstatus
    assert_includes stdout, "Single-use methods:"
    assert_includes stdout, "foo"
    refute_includes stdout, "Single-use variables:"
  end

  def test_variables_only_flag
    stdout, _stderr, status = run_cli("scan", "--variables-only", fixture_path("unused_variable.rb"))

    assert_equal 1, status.exitstatus
    assert_includes stdout, "Single-use variables:"
    assert_includes stdout, "x"
    refute_includes stdout, "Single-use methods:"
  end

  def test_methods_only_short_flag
    stdout, _stderr, status = run_cli("scan", "-m", fixture_path("unused_variable.rb"))

    assert_equal 1, status.exitstatus
    assert_includes stdout, "Single-use methods:"
    refute_includes stdout, "Single-use variables:"
  end

  def test_variables_only_short_flag
    stdout, _stderr, status = run_cli("scan", "-v", fixture_path("unused_variable.rb"))

    assert_equal 1, status.exitstatus
    assert_includes stdout, "Single-use variables:"
    refute_includes stdout, "Single-use methods:"
  end
end
