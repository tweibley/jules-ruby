## 2024-05-23 - [Actionable CLI Error Hints]

**Learning:** CLI users often encounter configuration errors (like missing API keys) but lack immediate knowledge of how to fix them. Providing specific, copy-pasteable hints (like `export JULES_API_KEY=...`) significantly improves the onboarding experience. However, these hints must be suppressed in JSON output modes to avoid breaking machine parsing.

**Action:** When implementing CLI error handlers, check for specific exception types (like `ConfigurationError`) and append actionable hints to the standard error output, ensuring they are skipped when `--format=json` is active.
