## 2025-12-18 - [Security] Validate Session URLs

**Vulnerability:** The interactive CLI opened URLs from API responses using `system('open', url)` without validation, allowing execution of potentially unsafe schemes (e.g., `file://`) or arbitrary commands if the URL was maliciously crafted.
**Learning:** `system('open', ...)` on macOS treats arguments as files or URLs, and can open applications. Trusting external input (even from our own API) for system commands carries risk.
**Prevention:** Always validate URL schemes (allowlist `http`, `https`) before passing them to system commands.

## 2025-12-23 - [Security] Enforce HTTPS for API Communication

**Vulnerability:** The client allowed non-secure `http` connections to be configured via `base_url`. This could allow a user to inadvertently send their API key in plain text over the network if they pointed the client to an insecure endpoint.
**Learning:** Even if the default URL is secure, the client should proactively prevent insecure configurations unless explicitly running on `localhost`.
**Prevention:** Added strict validation in `JulesRuby::Client#validate_configuration!` to raise `ConfigurationError` if `base_url` is not HTTPS (with exceptions for `localhost`, `127.0.0.1`, and `::1`).
