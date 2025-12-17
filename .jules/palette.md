## 2025-01-30 - [Helpful Configuration Error]

**Learning:** Users often run the CLI without setting up environment variables first. Catching `ConfigurationError` and providing a setup guide with copy-pasteable commands prevents "stack trace shock."
**Action:** When designing CLI entry points, always wrap the initial client instantiation in a rescue block that translates configuration errors into onboarding instructions.
