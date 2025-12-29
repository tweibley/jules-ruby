## 2024-05-23 - [Actionable Error Messages]

**Learning:** Developers often encounter `ConfigurationError` when setting up a new tool, but the error message rarely tells them *how* to fix it.
**Action:** When catching specific configuration errors in CLI tools, check the error type and append actionable hints (e.g., "export JULES_API_KEY=...") to standard error, while keeping JSON output clean for machine consumption.
