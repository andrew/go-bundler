#!/usr/bin/env ruby
# frozen_string_literal: true

require "go/bundler"

# Fetch a single module
Go::Bundler.fetch("github.com/rack/rack", "v3.1.8")

# Require using Go-style path
require "github.com/rack/rack"

puts "Rack version: #{Rack::VERSION}"

# You can also require submodules
require "github.com/rack/rack/request"
