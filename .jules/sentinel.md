## 2025-12-18 - [Security] Validate Session URLs

**Vulnerability:** The interactive CLI opened URLs from API responses using `system('open', url)` without validation, allowing execution of potentially unsafe schemes (e.g., `file://`) or arbitrary commands if the URL was maliciously crafted.
**Learning:** `system('open', ...)` on macOS treats arguments as files or URLs, and can open applications. Trusting external input (even from our own API) for system commands carries risk.
**Prevention:** Always validate URL schemes (allowlist `http`, `https`) before passing them to system commands.

## 2025-12-24 - [Missing HTTPS Enforcement]

**Vulnerability:** The client code was missing the HTTPS enforcement logic for `base_url` despite documentation claiming it existed. This could allow API keys to be sent over plain HTTP if a user configured a non-HTTPS URL.
**Learning:** Documentation and memory can drift from the actual codebase. Always verify security claims by inspecting the code or writing a test.
**Prevention:** Added explicit checks in `JulesRuby::Client#validate_configuration!` to enforce HTTPS for non-local hosts. Added a regression test in `spec/jules-ruby/security_spec.rb`.
