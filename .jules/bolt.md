## 2025-10-18 - Async::HTTP::Internet Usage

**Learning:** `Async::HTTP::Internet.new` is instantiated for every request in `JulesRuby::Client#request`, which likely prevents connection keep-alive/pooling.
**Action:** A significant future optimization would be to reuse the `Async::HTTP::Internet` instance, but this requires careful management of the `Async` reactor lifecycle since the current implementation wraps each request in its own `Async { ... }.wait` block.
