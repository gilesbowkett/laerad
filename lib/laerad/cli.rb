# frozen_string_literal: true

require "thor"

module Laerad
  class CLI < Thor
    def self.exit_on_failure?
      true
    end

    desc "scan PATH", "Scan Ruby files for single-use variables and methods"
    def scan(path = ".")
      result = Runner.new(path).run

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
