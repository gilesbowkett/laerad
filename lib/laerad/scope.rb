# frozen_string_literal: true

module Laerad
  class Scope
    attr_reader :variables, :variable_def_lines, :exempt_variables, :param_names

    def initialize
      @variables = Hash.new(0)
      @variable_def_lines = Hash.new { |h, k| h[k] = [] }
      @exempt_variables = Set.new
      @param_names = Set.new
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

    def variable_defined?(name)
      @variable_def_lines.key?(name)
    end
  end
end
