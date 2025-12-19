## 2025-10-18 - Async::HTTP::Internet Usage

**Learning:** `Async::HTTP::Internet.new` is instantiated for every request in `JulesRuby::Client#request`, which likely prevents connection keep-alive/pooling.
**Action:** A significant future optimization would be to reuse the `Async::HTTP::Internet` instance, but this requires careful management of the `Async` reactor lifecycle since the current implementation wraps each request in its own `Async { ... }.wait` block.

## 2025-12-18 - Failed Optimization: Connection Reuse

**Learning:** Attempted to reuse `Async::HTTP::Internet` in `JulesRuby::Client` to enable connection pooling. This failed because `JulesRuby::Client#request` wraps each call in a new `Async` reactor (`Async { ... }.wait`). Sockets are tied to the reactor they were created in; reusing them in a subsequent transient reactor causes errors or fails to work. Additionally, reusing the client instance makes `JulesRuby::Client` thread-unsafe.
**Action:** Do not attempt connection pooling unless the entire application architecture changes to use a persistent reactor or `JulesRuby::Client` is refactored to be purely async (returning Tasks instead of blocking).

## 2024-05-22 - ISO8601 Parsing

**Learning:** `Time.parse` is significantly slower (~4x) than `Time.iso8601` for parsing ISO8601 strings. Since the Jules API returns standard ISO8601 timestamps, using `Time.iso8601` is a safe and effective optimization for CLI rendering loops.
**Action:** Prefer `Time.iso8601` over `Time.parse` when the format is known to be ISO8601.
