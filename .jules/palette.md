## 2025-12-18 - Better API Error Messages

**Learning:** Users were receiving generic "Bad request" or "Server error" messages even when the API provided specific error details in the JSON body. This forced users to inspect exception objects to find the root cause.
**Action:** Updated `Client#handle_response` to parse and bubble up specific error messages from the API response (e.g., `error.message` in JSON), significantly improving debuggability.

## 2025-12-19 - Suppress Async Logs

**Learning:** `Async` logs unhandled exceptions even if they are caught by `wait`. This causes scary JSON logs to leak to the CLI output when an expected error (like 404) occurs.
**Action:** Wrap `Async` blocks in `begin/rescue` to catch exceptions inside the task, return them as values, and re-raise them outside the task to prevent noise.
