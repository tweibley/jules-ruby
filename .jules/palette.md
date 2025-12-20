## 2025-12-18 - Better API Error Messages

**Learning:** Users were receiving generic "Bad request" or "Server error" messages even when the API provided specific error details in the JSON body. This forced users to inspect exception objects to find the root cause.
**Action:** Updated `Client#handle_response` to parse and bubble up specific error messages from the API response (e.g., `error.message` in JSON), significantly improving debuggability.

## 2025-12-20 - Friendly CLI Configuration Errors

**Learning:** Users running the CLI without an API key encountered raw stack traces instead of helpful guidance. This violates the principle of "Good errors prevent frustration."
**Action:** Implemented `Prompts.print_config_error` to display a styled, actionable error message with instructions on how to set the `JULES_API_KEY` environment variable. Applied this handling to both interactive mode and subcommands.
