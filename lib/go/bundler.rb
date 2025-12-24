# frozen_string_literal: true

require_relative "bundler/version"

module Go
  module Bundler
    class Error < StandardError; end

    class << self
      def gopath
        @gopath ||= File.join(Dir.home, ".go-bundler")
      end

      def gopath=(path)
        @gopath = path
      end

      def mod_path
        File.join(gopath, "pkg", "mod")
      end

      def fetch(module_path, version = nil)
        spec = version ? "#{module_path}@#{version}" : module_path
        env = { "GOPATH" => gopath }
        system(env, "go", "get", spec, exception: true)
        module_root(module_path, version)
      end

      def module_root(module_path, version = nil)
        escaped = escape_path(module_path)
        pattern = File.join(mod_path, escaped + (version ? "@#{version}" : "@*"))
        dirs = Dir.glob(pattern).sort
        dirs.last
      end

      def install(gofile_path = "Gofile")
        deps = parse_gofile(gofile_path)
        deps.each { |mod, ver| fetch(mod, ver) }
      end

      def parse_gofile(path)
        return {} unless File.exist?(path)
        deps = {}
        File.readlines(path).each do |line|
          line = line.strip
          next if line.empty? || line.start_with?("#")
          parts = line.split(/\s+/)
          deps[parts[0]] = parts[1]
        end
        deps
      end

      def escape_path(path)
        path.gsub(/[A-Z]/) { |c| "!#{c.downcase}" }
      end

      def resolve_require(path)
        return nil unless path.include?("/")
        parts = path.split("/")
        return nil unless parts.length >= 3

        # Try github.com/org/repo first
        mod_path_candidate = parts[0, 3].join("/")
        root = module_root(mod_path_candidate)
        return nil unless root

        gem_name = parts[2]
        remainder = parts[3..]

        if remainder.empty?
          # require "github.com/rack/rack" -> look for lib/rack.rb
          lib_dir = File.join(root, "lib")
          main_file = File.join(lib_dir, "#{gem_name}.rb")
          return main_file if File.exist?(main_file)
          return lib_dir if File.directory?(lib_dir)
        else
          # require "github.com/rack/rack/request" -> lib/rack/request.rb
          lib_path = File.join(root, "lib", gem_name, *remainder) + ".rb"
          return lib_path if File.exist?(lib_path)
        end
        nil
      end
    end
  end
end

module Kernel
  alias_method :original_require, :require

  def require(path)
    if path.start_with?("github.com/", "gitlab.com/", "bitbucket.org/")
      resolved = Go::Bundler.resolve_require(path)
      if resolved
        if File.directory?(resolved)
          $LOAD_PATH.unshift(resolved) unless $LOAD_PATH.include?(resolved)
          return original_require(File.basename(path))
        else
          return original_require(resolved)
        end
      end
    end
    original_require(path)
  end
end
