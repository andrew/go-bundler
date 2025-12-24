# frozen_string_literal: true

require "test_helper"
require "tmpdir"
require "fileutils"

class Go::TestBundler < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Go::Bundler::VERSION
  end

  def test_escape_path_lowercases_uppercase
    assert_equal "!burnt!sushi/toml", Go::Bundler.escape_path("BurntSushi/toml")
  end

  def test_escape_path_leaves_lowercase_alone
    assert_equal "github.com/rack/rack", Go::Bundler.escape_path("github.com/rack/rack")
  end

  def test_escape_path_mixed_case
    assert_equal "github.com/!azure/azure-sdk", Go::Bundler.escape_path("github.com/Azure/azure-sdk")
  end

  def test_parse_gofile
    Dir.mktmpdir do |dir|
      gofile = File.join(dir, "Gofile")
      File.write(gofile, <<~GOFILE)
        # This is a comment
        github.com/rack/rack v3.1.8
        github.com/sinatra/sinatra v4.1.1

        github.com/rails/rails v7.0.0
      GOFILE

      deps = Go::Bundler.parse_gofile(gofile)

      assert_equal 3, deps.size
      assert_equal "v3.1.8", deps["github.com/rack/rack"]
      assert_equal "v4.1.1", deps["github.com/sinatra/sinatra"]
      assert_equal "v7.0.0", deps["github.com/rails/rails"]
    end
  end

  def test_parse_gofile_missing_file
    deps = Go::Bundler.parse_gofile("/nonexistent/Gofile")
    assert_equal({}, deps)
  end

  def test_module_root_returns_nil_when_not_found
    Go::Bundler.gopath = "/nonexistent/path"
    assert_nil Go::Bundler.module_root("github.com/fake/module")
  end

  def test_module_root_finds_versioned_module
    Dir.mktmpdir do |dir|
      Go::Bundler.gopath = dir
      mod_dir = File.join(dir, "pkg", "mod", "github.com", "rack", "rack@v3.1.8")
      FileUtils.mkdir_p(mod_dir)

      result = Go::Bundler.module_root("github.com/rack/rack", "v3.1.8")
      assert_equal mod_dir, result
    end
  end

  def test_module_root_finds_latest_version
    Dir.mktmpdir do |dir|
      Go::Bundler.gopath = dir
      FileUtils.mkdir_p(File.join(dir, "pkg", "mod", "github.com", "rack", "rack@v3.1.7"))
      FileUtils.mkdir_p(File.join(dir, "pkg", "mod", "github.com", "rack", "rack@v3.1.8"))

      result = Go::Bundler.module_root("github.com/rack/rack")
      assert result.end_with?("rack@v3.1.8")
    end
  end

  def test_resolve_require_finds_lib_file
    Dir.mktmpdir do |dir|
      Go::Bundler.gopath = dir
      mod_dir = File.join(dir, "pkg", "mod", "github.com", "rack", "rack@v3.1.8")
      lib_dir = File.join(mod_dir, "lib")
      FileUtils.mkdir_p(lib_dir)
      File.write(File.join(lib_dir, "rack.rb"), "# rack")

      result = Go::Bundler.resolve_require("github.com/rack/rack")
      assert_equal File.join(lib_dir, "rack.rb"), result
    end
  end

  def test_resolve_require_finds_submodule
    Dir.mktmpdir do |dir|
      Go::Bundler.gopath = dir
      mod_dir = File.join(dir, "pkg", "mod", "github.com", "rack", "rack@v3.1.8")
      lib_dir = File.join(mod_dir, "lib", "rack")
      FileUtils.mkdir_p(lib_dir)
      File.write(File.join(lib_dir, "request.rb"), "# request")

      result = Go::Bundler.resolve_require("github.com/rack/rack/request")
      assert_equal File.join(mod_dir, "lib", "rack", "request.rb"), result
    end
  end

  def test_resolve_require_returns_nil_for_short_paths
    assert_nil Go::Bundler.resolve_require("rack")
    assert_nil Go::Bundler.resolve_require("foo/bar")
  end

  def test_resolve_require_returns_nil_when_not_found
    Go::Bundler.gopath = "/nonexistent"
    assert_nil Go::Bundler.resolve_require("github.com/fake/module")
  end

  def teardown
    Go::Bundler.gopath = nil
  end
end
