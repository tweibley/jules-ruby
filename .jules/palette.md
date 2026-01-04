## 2024-05-23 - Actionable Configuration Errors

**Learning:** Developers often run the CLI for the first time without setting up the environment. A generic "API key is required" error is technically correct but friction-heavy.
**Action:** Detect specific error types (like `ConfigurationError`) in the top-level error handler and append specific, copy-pasteable solution hints (e.g., `export JULES_API_KEY=...`) and documentation links. Ensure these hints are suppressed in JSON output mode to keep the API machine-readable.
