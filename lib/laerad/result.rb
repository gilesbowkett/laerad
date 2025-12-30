# frozen_string_literal: true

require "terminal-table"

module Laerad
  class Result
    attr_reader :file, :variable_violations

    def initialize(file: nil, variable_violations: [])
      @file = file
      @variable_violations = variable_violations
    end

    def add_variable_violation(name:, line:, count:)
      @variable_violations << {name: name, line: line, count: count}
    end

    def violations?
      @variable_violations.any?
    end

    def self.merge(*results)
      merged_variable_violations = []

      results.each do |result|
        result.variable_violations.each do |v|
          merged_variable_violations << v.merge(file: result.file)
        end
      end

      new(variable_violations: merged_variable_violations)
    end

    def format_output(short: false)
      return "" if @variable_violations.empty?

      if short
        @variable_violations.map do |v|
          file_path = v[:file] || @file
          "#{file_path}:#{v[:line]}"
        end.join("\n")
      else
        rows = @variable_violations.map do |v|
          file_path = v[:file] || @file
          [file_path, v[:line], v[:name], v[:count]]
        end

        table = Terminal::Table.new(
          headings: ["File", "Line", "Variable", "Appearances"],
          rows: rows
        )

        table.to_s
      end
    end
  end
end
