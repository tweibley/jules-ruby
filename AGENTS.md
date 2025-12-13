# AI Agent Guide for jules-ruby

This document helps AI coding agents understand the codebase structure, conventions, and common commands.

## Project Overview

**jules-ruby** is a Ruby gem providing a client for the [Jules API](https://developers.google.com/jules/api) to programmatically create and manage asynchronous coding tasks. It includes both a Ruby library and a CLI with interactive TUI mode.

## Project Structure

```
jules-ruby/
├── lib/
│   ├── jules-ruby.rb              # Main entry point, requires all modules
│   └── jules-ruby/
│       ├── client.rb              # HTTP client with async-http
│       ├── configuration.rb       # Global config (api_key, timeout)
│       ├── errors.rb              # Custom error classes
│       ├── version.rb             # Gem version
│       ├── cli.rb                 # Thor-based CLI commands
│       ├── cli/
│       │   ├── banner.rb          # CLI banner/logo display
│       │   ├── interactive.rb     # Interactive TUI mode (TTY::Prompt)
│       │   └── prompts.rb         # Shared prompt helpers
│       ├── models/                # Data objects returned from API
│       │   ├── activity.rb
│       │   ├── artifact.rb
│       │   ├── github_repo.rb
│       │   ├── github_branch.rb
│       │   ├── plan.rb
│       │   ├── plan_step.rb
│       │   ├── pull_request.rb
│       │   ├── session.rb
│       │   ├── source.rb
│       │   └── source_context.rb
│       └── resources/             # API resource classes
│           ├── base.rb            # Base resource with HTTP methods
│           ├── activities.rb
│           ├── sessions.rb
│           └── sources.rb
├── bin/
│   └── jules-ruby                 # CLI executable
├── spec/                          # RSpec tests
└── .env                           # API key configuration (JULES_API_KEY)
```

## Common Commands

```bash
# Install dependencies
bundle install

# Run tests
bundle exec rspec

# Run linter
bundle exec rubocop

# Fix lint issues automatically
bundle exec rubocop -a

# Build the gem
gem build jules-ruby.gemspec

# Install locally
gem install ./jules-ruby-*.gem
```

## Environment Setup (Already setup on Jules)

These commands were already run on Jules to prepare the environment:

```bash
# Install system dependencies and mise
sudo apt update -y && sudo apt install -y curl
sudo apt-get install -y libssl-dev libyaml-dev zlib1g-dev libreadline-dev libgdbm-dev
curl https://mise.run | sh
export PATH="$HOME/.local/bin:$PATH"

# Activate mise and install Ruby (from mise.toml)
eval "$(mise activate bash --shims)"
mise trust -a
mise install

# Install gem dependencies
gem install --quiet bundler rake
bundle install
```

## Code Style Guidelines

### Ruby Version
- Target Ruby 3.0+ (`required_ruby_version >= 3.0.0`)

### RuboCop Configuration
Key settings from `.rubocop.yml`:
- **Line length**: Max 120 characters
- **Method length**: Max 20 lines
- **Class length**: Max 150 lines
- **ABC size**: Max 25
- **Cyclomatic complexity**: Max 10
- Documentation cop is disabled

### Naming Conventions
- **Module**: `JulesRuby` (camelCase)
- **Gem name**: `jules-ruby` (hyphenated, matching file paths)
- **Files**: Hyphenated to match gem name (`jules-ruby/` directory)

### Architecture Patterns

1. **Models** (`lib/jules-ruby/models/`): Plain Ruby objects with:
   - `initialize(attributes = {})` accepting a hash
   - Attribute readers for all fields
   - Convenience methods for state checking (e.g., `session.completed?`)
   - `from_api_response(data)` class method for parsing API responses

2. **Resources** (`lib/jules-ruby/resources/`): API endpoint wrappers extending `Base`:
   - `list(params)` - Returns `{ resource_name: [], next_page_token: nil }`
   - `find(id)` - Returns single model instance
   - `all(params)` - Fetches all pages, returns array
   - `create(params)` - For writable resources

3. **Client** (`lib/jules-ruby/client.rb`): Entry point providing:
   - `client.sources`, `client.sessions`, `client.activities` resource accessors
   - Uses `async-http` for HTTP requests
   - Handles authentication via `Authorization: Bearer` header

4. **CLI** (`lib/jules-ruby/cli.rb`): Thor-based commands:
   - Subcommands: `sources`, `sessions`, `activities`, `interactive`
   - Output formats: `--format=table` (default) or `--format=json`

## Dependencies

### Runtime
- `async-http ~> 0.75` - Async HTTP client
- `dotenv ~> 3.0` - Environment variable loading
- `thor ~> 1.3` - CLI framework
- `tty-prompt ~> 0.23` - Interactive prompts
- `tty-spinner ~> 0.9` - Loading spinners
- `pastel ~> 0.8` - Terminal output styling

### Development
- `rspec ~> 3.0` - Testing
- `webmock ~> 3.0` - HTTP request stubbing
- `rubocop ~> 1.0` - Linting
- `simplecov ~> 0.22` - Code coverage

## Configuration

The gem uses `JULES_API_KEY` from environment or `.env` file:

```ruby
# Option 1: Environment variable
ENV['JULES_API_KEY'] = 'your_key'

# Option 2: Block configuration
JulesRuby.configure do |config|
  config.api_key = 'your_key'
  config.timeout = 60
end

# Option 3: Per-client
client = JulesRuby::Client.new(api_key: 'your_key')
```

## Error Handling

Custom errors in `lib/jules-ruby/errors.rb`:
- `JulesRuby::Error` - Base error class
- `JulesRuby::AuthenticationError` - 401/403 responses
- `JulesRuby::NotFoundError` - 404 responses
- `JulesRuby::RateLimitError` - 429 responses
- `JulesRuby::ServerError` - 5xx responses

## API Reference

The gem wraps the Jules API documented at: https://developers.google.com/jules/api

Main resources:
- **Sources**: Connected GitHub repositories
- **Sessions**: Coding task sessions (create, approve plans, send messages)
- **Activities**: Session events/history (messages, plans, progress updates)
