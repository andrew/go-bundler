#!/usr/bin/env ruby
# frozen_string_literal: true

require "go/bundler"

# Install dependencies from Gofile
Go::Bundler.install("Gofile")

# Now require using Go-style paths
require "github.com/rack/rack"
require "github.com/sinatra/sinatra"

class App < Sinatra::Base
  get "/" do
    "Hello from go-bundler!"
  end
end

run App
