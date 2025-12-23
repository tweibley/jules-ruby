## 2025-12-18 - Better API Error Messages

**Learning:** Users were receiving generic "Bad request" or "Server error" messages even when the API provided specific error details in the JSON body. This forced users to inspect exception objects to find the root cause.
**Action:** Updated `Client#handle_response` to parse and bubble up specific error messages from the API response (e.g., `error.message` in JSON), significantly improving debuggability.

## 2024-12-23 - Input Validation for Resource Lookups

**Learning:** Resource lookup methods like `find(nil)` or `find("")` were raising confusing `NoMethodError` or causing API `404` errors instead of informing the user about invalid input.
**Action:** Added explicit input validation raising `ArgumentError` with descriptive messages to all resource lookup methods (`find`, `list`) and path helpers. This fails fast and guides the user.
