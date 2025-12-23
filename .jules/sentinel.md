## 2025-12-18 - [Security] Validate Session URLs

**Vulnerability:** The interactive CLI opened URLs from API responses using `system('open', url)` without validation, allowing execution of potentially unsafe schemes (e.g., `file://`) or arbitrary commands if the URL was maliciously crafted.
**Learning:** `system('open', ...)` on macOS treats arguments as files or URLs, and can open applications. Trusting external input (even from our own API) for system commands carries risk.
**Prevention:** Always validate URL schemes (allowlist `http`, `https`) before passing them to system commands.

## 2025-12-23 - Terminal ANSI Injection via Input

**Vulnerability:** Untrusted input could contain ANSI escape codes, allowing display spoofing or terminal manipulation when rendered in the CLI.
**Learning:** CLI applications must sanitize input before applying their own styling, just like web apps sanitize HTML.
**Prevention:** Always strip ANSI codes from dynamic text before wrapping it in color helpers.
