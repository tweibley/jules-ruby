## 2024-05-23 - Actionable Error Messages

**Learning:** Developers often struggle with configuration errors when first setting up a CLI. Providing specific, actionable hints directly in the error output significantly improves the onboarding experience.
**Action:** When catching known errors (like `ConfigurationError`), append a "Tip" section with specific environment variables to check and a link to documentation. Ensure this is done in a way that preserves JSON output for machine parsing.

## 2024-05-23 - Thor vs External Coloring

**Learning:** When working within a specific framework like Thor, use its built-in capabilities (e.g., `shell.set_color`) rather than introducing or using external libraries (like `Pastel`) for core functionality, even if they are available in the project. This keeps the core command logic robust and consistent with the framework's design.
**Action:** Always check if the current framework provides the desired functionality before adding new dependencies or using peripheral ones. For Thor CLIs, use `shell.set_color` for output styling.
