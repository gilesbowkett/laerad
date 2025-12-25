# frozen_string_literal: true

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

    def format_output
      output = []

      if @variable_violations.any?
        output << "Single-use variables:"
        @variable_violations.each do |v|
          file_path = v[:file] || @file
          output << "  #{file_path}:#{v[:line]}  #{v[:name]} (#{v[:count]} use)"
        end
        output << ""
      end

      output.join("\n")
    end
  end
end
