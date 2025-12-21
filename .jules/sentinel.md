## 2025-12-18 - [Security] Validate Session URLs

**Vulnerability:** The interactive CLI opened URLs from API responses using `system('open', url)` without validation, allowing execution of potentially unsafe schemes (e.g., `file://`) or arbitrary commands if the URL was maliciously crafted.
**Learning:** `system('open', ...)` on macOS treats arguments as files or URLs, and can open applications. Trusting external input (even from our own API) for system commands carries risk.
**Prevention:** Always validate URL schemes (allowlist `http`, `https`) before passing them to system commands.

## 2025-12-21 - Terminal Injection via ANSI Escape Sequences

**Vulnerability:** User-controlled input (e.g., session titles, messages) could contain ANSI escape sequences, which were rendered raw in the CLI via `rgb_color`, potentially allowing terminal manipulation.
**Learning:** Even "cosmetic" helpers like color formatting need input sanitization when handling untrusted data.
**Prevention:** Sanitize all inputs before applying terminal formatting. Used `Pastel#strip` to remove existing ANSI codes.
