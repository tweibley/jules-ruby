## 2025-10-18 - Async::HTTP::Internet Usage

**Learning:** `Async::HTTP::Internet.new` is instantiated for every request in `JulesRuby::Client#request`, which likely prevents connection keep-alive/pooling.
**Action:** A significant future optimization would be to reuse the `Async::HTTP::Internet` instance, but this requires careful management of the `Async` reactor lifecycle since the current implementation wraps each request in its own `Async { ... }.wait` block.

## 2025-12-18 - Failed Optimization: Connection Reuse

**Learning:** Attempted to reuse `Async::HTTP::Internet` in `JulesRuby::Client` to enable connection pooling. This failed because `JulesRuby::Client#request` wraps each call in a new `Async` reactor (`Async { ... }.wait`). Sockets are tied to the reactor they were created in; reusing them in a subsequent transient reactor causes errors or fails to work. Additionally, reusing the client instance makes `JulesRuby::Client` thread-unsafe.
**Action:** Do not attempt connection pooling unless the entire application architecture changes to use a persistent reactor or `JulesRuby::Client` is refactored to be purely async (returning Tasks instead of blocking).

## 2025-05-23 - URL Construction Optimization

**Learning:** `URI.parse` is significantly slower (14x slower for empty params, 3x slower with params) than string interpolation for constructing URLs. By replacing `URI.parse` with manual string manipulation in `JulesRuby::Client#build_url`, we achieved a measurable performance boost.
**Action:** Prefer string interpolation over `URI.parse` for constructing URLs in hot paths, especially when the base URL and path format are controlled and simple. However, great care must be taken to replicate `URI`'s behavior exactly regarding query string replacement and fragment preservation.
