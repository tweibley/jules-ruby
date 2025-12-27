## 2025-12-23 - [CRITICAL] Insecure HTTP allowed for API

**Vulnerability:** The client allowed non-HTTPS `base_url` configurations for remote hosts, potentially exposing the `X-Goog-Api-Key` header in plain text over the network.
**Learning:** Checking for the presence of an API key is insufficient; the transport security (HTTPS) must also be enforced when the key is transmitted.
**Prevention:** Added strict validation in `JulesRuby::Client` to raise `ConfigurationError` if `base_url` is not HTTPS, unless the host is `localhost`, `127.0.0.1`, or `[::1]`.
