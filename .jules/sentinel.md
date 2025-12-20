## 2025-12-20 - [Terminal Injection Prevention]

**Vulnerability:** User input or external data containing ANSI escape codes could manipulate terminal output, potentially spoofing status messages or hiding information.
**Learning:** CLI tools often concatenate strings for display. If one part comes from an untrusted source and contains `\e[...m` codes, it can bleed into subsequent text or reset formatting unexpectedly.
**Prevention:** Sanitize input strings in coloring helpers (like `rgb_color`) by stripping existing ANSI codes before applying new colors. Use `Pastel#strip` or regex.
