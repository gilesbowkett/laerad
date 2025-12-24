# frozen_string_literal: true

require "thor"

module Laerad
  class CLI < Thor
    def self.exit_on_failure?
      true
    end

    desc "scan PATH", "Scan Ruby files for single-use variables and methods"
    method_option :methods_only, type: :boolean, aliases: "-m", desc: "Only check for single-use methods"
    method_option :variables_only, type: :boolean, aliases: "-v", desc: "Only check for single-use variables"
    def scan(path = ".")
      result = Runner.new(path, options).run

      if result.violations?
        puts result.format_output
        exit 1
      else
        puts "No violations found."
        exit 0
      end
    end

    desc "version", "Print version"
    def version
      puts "laerad #{VERSION}"
    end

    default_task :scan
  end
end
