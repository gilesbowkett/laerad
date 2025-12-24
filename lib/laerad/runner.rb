# frozen_string_literal: true

module Laerad
  class Runner
    def initialize(paths)
      @paths = Array(paths)
    end

    def run
      files = expand_paths
      results = files.map { |file| FileAnalyzer.analyze(file) }
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
