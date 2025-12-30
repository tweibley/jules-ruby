## 2024-05-23 - [Insecure Client Base URL]

**Vulnerability:** The client allowed `http://` schemes for `base_url`, which would transmit the API key in cleartext over the network.
**Learning:** Documented security features (like HTTPS enforcement) can sometimes be missing from the actual implementation if they aren't enforced by tests. The discrepancy between documentation/memory and code was the key indicator.
**Prevention:** Enforce HTTPS in the configuration validation step and explicitly test for both secure (HTTPS) and insecure (HTTP) configurations, including exceptions for local development.
