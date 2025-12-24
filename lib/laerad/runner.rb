# frozen_string_literal: true

module Laerad
  class Runner
    def initialize(paths, options = {})
      @paths = Array(paths)
      @options = options
    end

    def run
      files = expand_paths
      results = files.map { |file| FileAnalyzer.analyze(file, @options) }
      Result.merge(*results)
    end

    private

    def expand_paths
      @paths.flat_map do |path|
        if File.directory?(path)
          Dir.glob(File.join(path, "**", "*.rb"))
        elsif File.file?(path) && path.end_with?(".rb")
          [path]
        else
          []
        end
      end
    end
  end
end
