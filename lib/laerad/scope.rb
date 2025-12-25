# frozen_string_literal: true

module Laerad
  class Scope
    attr_reader :variables, :methods, :variable_def_lines, :method_def_lines

    def initialize
      @variables = Hash.new(0)
      @methods = Hash.new(0)
      @variable_def_lines = Hash.new { |h, k| h[k] = [] }
      @method_def_lines = Hash.new { |h, k| h[k] = [] }
      @dynamic = false
    end

    def register_variable_def(name, line)
      @variables[name] += 1
      @variable_def_lines[name] << line
    end

    def register_variable_ref(name)
      @variables[name] += 1
    end

    def register_method_def(name, line)
      @methods[name] += 1
      @method_def_lines[name] << line
    end

    def register_method_call(name)
      @methods[name] += 1
    end

    def mark_dynamic!
      @dynamic = true
    end

    def dynamic?
      @dynamic
    end

    def single_use_variables
      @variables.select { |_, count| count <= 2 }.keys
    end

    def single_use_methods
      return [] if dynamic?
      @methods.select { |_, count| count <= 2 }.keys
    end

    def variable_definition_line(name)
      @variable_def_lines[name].first
    end

    def method_definition_line(name)
      @method_def_lines[name].first
    end

    def variable_count(name)
      @variables[name]
    end

    def method_count(name)
      @methods[name]
    end
  end
end
