# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2025-12-18

### Added
- Better API error messages with detailed extraction from JSON responses
- URL scheme validation (allowlist `http`/`https`) in interactive CLI

### Changed
- Optimized `Session#active?` with frozen `ACTIVE_STATES` constant to reduce allocations

### Security
- Fixed unsafe URL opening vulnerability in interactive CLI (MEDIUM severity)

## [0.0.67] - 2025-12-17

### Added
- CLI with commands for sources, sessions, and activities
- Interactive TUI mode (`jules-ruby interactive`)
- JSON output format (`--format=json`)
- Ruby client library for Jules API
- Session management (create, approve, message, delete)
- Activity monitoring with pagination
- Source repository listing

### Changed
- Initial public release
