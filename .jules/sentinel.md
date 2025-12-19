## 2025-12-18 - [Security] Validate Session URLs

**Vulnerability:** The interactive CLI opened URLs from API responses using `system('open', url)` without validation, allowing execution of potentially unsafe schemes (e.g., `file://`) or arbitrary commands if the URL was maliciously crafted.
**Learning:** `system('open', ...)` on macOS treats arguments as files or URLs, and can open applications. Trusting external input (even from our own API) for system commands carries risk.
**Prevention:** Always validate URL schemes (allowlist `http`, `https`) before passing them to system commands.

## 2024-05-22 - CLI ANSI Injection

**Vulnerability:** CLI output helpers allowed ANSI escape sequence injection via user-controlled data.
**Learning:** Ruby's `puts` and terminal output libraries don't automatically sanitize control characters.
**Prevention:** Added sanitization in `Prompts.rgb_color` using `Pastel.strip` to prevent style injection.
