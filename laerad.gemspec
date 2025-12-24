# frozen_string_literal: true

require_relative "lib/laerad/version"

Gem::Specification.new do |spec|
  spec.name = "laerad"
  spec.version = Laerad::VERSION
  spec.authors = ["Giles Bowkett"]
  spec.summary = "Static analyzer to detect single-use variables and methods in Ruby code"
  spec.homepage = "https://github.com/gilesbowkett/laerad"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.4.7"

  spec.files = Dir["lib/**/*.rb", "bin/*", "README.md", "LICENSE"]
  spec.bindir = "bin"
  spec.executables = ["laerad"]
  spec.require_paths = ["lib"]

  spec.add_dependency "syntax_tree"
  spec.add_dependency "thor"
end
