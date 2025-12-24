# go-bundler

**Do not use this.** It's a joke that happens to work.

Go-style imports for Ruby:

```ruby
require "github.com/rack/rack"
require "github.com/rails/rails"
```

Uses Go's module proxy to fetch Ruby gems. See [the blog post](https://nesbitt.io/2025/12/25/go-get-for-rubygems.html) for the full explanation.

## Usage

Create a `Gofile` listing dependencies:

```
github.com/rack/rack v3.1.8
github.com/sinatra/sinatra v4.1.1
```

Then in your Ruby code:

```ruby
require "go/bundler"

Go::Bundler.install("Gofile")

require "github.com/rack/rack"
require "github.com/sinatra/sinatra"
```

Or fetch manually:

```ruby
require "go/bundler"

Go::Bundler.fetch("github.com/rack/rack", "v3.1.8")

require "github.com/rack/rack"
require "github.com/rack/rack/request"
```

## Requirements

- Go installed and in PATH
- Ruby gems must have a `go.mod` file at repo root
- Versions come from git tags

## How it works

Go's module proxy caches any repo with a `go.mod` file and logs its hash in a transparency log. It doesn't check that the repo contains Go code. This gem hooks Ruby's `require` to resolve `github.com/org/repo` paths to modules fetched via `go get`.

Modules land in `~/.go-bundler/pkg/mod/github.com/org/repo@version/`. The require hook finds the right `lib/` directory and loads from there.

Seriously, don't use this.
