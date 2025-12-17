# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = "jules-ruby"
  spec.version       = "0.0.67"
  spec.authors       = ["Taylor Weibley"]
  spec.email         = ["tweibley@gmail.com"]

  spec.summary       = "Ruby CLI for the Jules API"
  spec.description   = "A Ruby gem for interacting with the Jules API to programmatically create and manage asynchronous coding tasks."
  spec.homepage      = "https://github.com/tweibley/jules-ruby"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[test/ spec/ features/ .git .github Gemfile])
    end
  end
  spec.bindir = "bin"
  spec.executables = ['jules-ruby']
  spec.require_paths = ["lib"]

  spec.add_dependency "async-http", "~> 0.75"
  spec.add_dependency "dotenv", "~> 3.0"
  spec.add_dependency "thor", "~> 1.3"
  spec.add_dependency "tty-prompt", "~> 0.23"
  spec.add_dependency "tty-spinner", "~> 0.9"
  spec.add_dependency "pastel", "~> 0.8"

  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "webmock", "~> 3.0"
  spec.add_development_dependency "rubocop", "~> 1.0"
  spec.add_development_dependency "simplecov", "~> 0.22"
end
