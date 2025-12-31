## 2024-05-22 - Actionable Configuration Errors

**Learning:** Users often struggle with initial setup (like API keys). Providing a direct link to where they can solve the problem (e.g., developer console) significantly reduces friction. However, we must be careful not to corrupt machine-readable output (JSON) with human-readable hints.
**Action:** When catching configuration errors in the CLI, append actionable hints (URLs, commands) only when in interactive/text mode. Suppress them for JSON output to ensure scripts don't break.
