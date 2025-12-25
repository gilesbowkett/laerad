# frozen_string_literal: true

require "pronto"
require "laerad"

module Pronto
  class Laerad < Runner
    def run
      return [] unless @patches

      @patches
        .select { |patch| patch.delta.new_file[:path].end_with?(".rb") }
        .flat_map { |patch| inspect(patch) }
    end

    private

    def inspect(patch)
      path = patch.delta.new_file[:path]
      result = ::Laerad::FileAnalyzer.analyze(path)

      result.variable_violations.filter_map do |violation|
        line = patch.added_lines.find { |l| l.new_lineno == violation[:line] }
        next unless line

        Message.new(
          path,
          line,
          :warning,
          "#{violation[:name]} is a single-use variable",
          nil,
          self.class
        )
      end
    end
  end
end
