## 2025-12-18 - [Security] Validate Session URLs

**Vulnerability:** The interactive CLI opened URLs from API responses using `system('open', url)` without validation, allowing execution of potentially unsafe schemes (e.g., `file://`) or arbitrary commands if the URL was maliciously crafted.
**Learning:** `system('open', ...)` on macOS treats arguments as files or URLs, and can open applications. Trusting external input (even from our own API) for system commands carries risk.
**Prevention:** Always validate URL schemes (allowlist `http`, `https`) before passing them to system commands.

## 2025-12-22 - [Terminal Injection Prevention]

**Vulnerability:** `rgb_color` helper was interpolating raw text into ANSI escape sequences without sanitization, allowing potential terminal injection attacks via API responses containing ANSI codes.
**Learning:** Even simple CLI display helpers need to sanitize input, especially when handling data from external sources (APIs). Memory records regarding security controls can be outdated or incorrect.
**Prevention:** Always strip existing ANSI codes before applying new ones in color helpers using `Pastel#strip`.
