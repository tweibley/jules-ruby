## 2025-12-18 - Better API Error Messages

**Learning:** Users were receiving generic "Bad request" or "Server error" messages even when the API provided specific error details in the JSON body. This forced users to inspect exception objects to find the root cause.
**Action:** Updated `Client#handle_response` to parse and bubble up specific error messages from the API response (e.g., `error.message` in JSON), significantly improving debuggability.

## 2025-12-18 - Multiline Input for Complex Prompts

**Learning:** Single-line inputs are frustrating for coding tasks that require detailed instructions or pasted snippets. Users often hit Enter prematurely or struggle to review their input.
**Action:** Use `TTY::Prompt#multiline` for inputs expected to be longer than a sentence (like prompts or messages), providing clear instructions on how to terminate input (e.g., "Press Ctrl+D").
