## 2025-12-18 - Better API Error Messages

**Learning:** Users were receiving generic "Bad request" or "Server error" messages even when the API provided specific error details in the JSON body. This forced users to inspect exception objects to find the root cause.
**Action:** Updated `Client#handle_response` to parse and bubble up specific error messages from the API response (e.g., `error.message` in JSON), significantly improving debuggability.

## 2025-12-22 - Fail Fast with Helpful Errors

**Learning:** Resource `find` methods silently crashed with `NoMethodError` or made invalid requests when passed `nil` or empty strings. This is a common pattern where lack of input validation leads to confusing debugging.
**Action:** Added explicit validation to raise `ArgumentError` with descriptive messages (e.g., "Session ID or name is required") at the beginning of public methods. This aligns with the "Good errors prevent frustration" principle.
