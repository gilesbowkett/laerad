# frozen_string_literal: true

module Laerad
  class Scope
    attr_reader :variables, :variable_def_lines

    def initialize
      @variables = Hash.new(0)
      @variable_def_lines = Hash.new { |h, k| h[k] = [] }
    end

    def register_variable_def(name, line)
      @variables[name] += 1
      @variable_def_lines[name] << line
    end

    def register_variable_ref(name)
      @variables[name] += 1
    end

    def single_use_variables
      @variables.select { |_, count| count <= 2 }.keys
    end

    def variable_definition_line(name)
      @variable_def_lines[name].first
    end

    def variable_count(name)
      @variables[name]
    end
  end
end
