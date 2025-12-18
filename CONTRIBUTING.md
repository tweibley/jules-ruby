# Contributing to Jules Ruby

Thank you for your interest in contributing to jules-ruby!

## Development Setup

1. Fork and clone the repository:
   ```bash
   git clone https://github.com/YOUR_USERNAME/jules-ruby.git
   cd jules-ruby
   ```

2. Install dependencies:
   ```bash
   bundle install
   ```

3. Set up your API key for testing:
   ```bash
   cp .env.example .env
   # Edit .env with your Jules API key
   ```

## Running Tests

```bash
# Run the test suite
bundle exec rspec

# Run with coverage report
COVERAGE=true bundle exec rspec

# Run linter
bundle exec rubocop

# Auto-fix linting issues
bundle exec rubocop -a
```

## Making Changes

1. Create a feature branch:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. Make your changes and ensure:
   - All tests pass (`bundle exec rspec`)
   - Code follows style guidelines (`bundle exec rubocop`)
   - New code has test coverage

3. Commit with a clear message:
   ```bash
   git commit -m "Add feature: brief description"
   ```

4. Push and open a Pull Request

## Pull Request Guidelines

- Keep PRs focused on a single change
- Update documentation if adding new features
- Add tests for new functionality
- Update CHANGELOG.md under "Unreleased" section

## Release Process (Maintainers)

1. Update version in `jules-ruby.gemspec`
2. Update `CHANGELOG.md` with release notes
3. Commit: `git commit -am "Bump version to X.Y.Z"`
4. Tag: `git tag vX.Y.Z`
5. Push: `git push origin main --tags`

The GitHub Actions release workflow will automatically:
- Build the gem
- Generate checksums
- Publish to RubyGems.org
- Create a GitHub Release

## Code of Conduct

Be kind and respectful. We're all here to learn and build together.
