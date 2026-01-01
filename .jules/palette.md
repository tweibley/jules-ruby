## 2024-03-21 - [Actionable Configuration Errors]

**Learning:** Developers often forget to set environment variables like `JULES_API_KEY`, and a generic error message forces them to context switch to docs.
**Action:** When a `ConfigurationError` occurs in the CLI, print the exact command to fix it (`export JULES_API_KEY=...`) right in the error output. This pattern (Problem -> Solution -> Command) significantly reduces friction for first-time users.
