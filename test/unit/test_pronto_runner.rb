# frozen_string_literal: true

require "test_helper"
require "pronto"
require "pronto/laerad"

class TestProntoRunner < Minitest::Test
  def fixture_path(name)
    File.expand_path("../fixtures/#{name}", __dir__)
  end

  def test_run_returns_empty_array_when_no_patches
    runner = Pronto::Laerad.new(nil)

    assert_equal [], runner.run
  end

  def test_run_ignores_non_ruby_files
    patch = mock_patch("test.txt", [])
    runner = Pronto::Laerad.new([patch])

    assert_equal [], runner.run
  end

  def test_run_returns_messages_for_violations_on_changed_lines
    path = fixture_path("single_use_variable.rb")
    patch = mock_patch(path, [2])
    runner = Pronto::Laerad.new([patch])

    messages = runner.run

    assert_equal 1, messages.size
    assert_equal :warning, messages.first.level
    assert_match(/is a single-use variable/, messages.first.msg)
  end

  def test_run_ignores_violations_not_on_changed_lines
    path = fixture_path("single_use_variable.rb")
    patch = mock_patch(path, [999])
    runner = Pronto::Laerad.new([patch])

    messages = runner.run

    assert_equal [], messages
  end

  def test_run_returns_empty_for_clean_files
    path = fixture_path("no_violations.rb")
    patch = mock_patch(path, [1, 2, 3])
    runner = Pronto::Laerad.new([patch])

    messages = runner.run

    assert_equal [], messages
  end

  def test_message_includes_variable_name
    path = fixture_path("single_use_variable.rb")
    patch = mock_patch(path, [2])
    runner = Pronto::Laerad.new([patch])

    messages = runner.run

    assert_equal "x is a single-use variable", messages.first.msg
  end

  private

  def mock_patch(path, changed_lines)
    delta = Struct.new(:new_file).new({path: path})
    line_class = Struct.new(:new_lineno, :commit_sha)
    added_lines = changed_lines.map { |n| line_class.new(n, "abc123") }

    patch = Object.new
    patch.define_singleton_method(:delta) { delta }
    patch.define_singleton_method(:added_lines) { added_lines }
    patch
  end
end
