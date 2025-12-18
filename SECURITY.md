# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 0.0.x   | :white_check_mark: |

## Reporting a Vulnerability

If you discover a security vulnerability in jules-ruby, please report it responsibly:

1. **Do not** open a public GitHub issue
2. Email the maintainers at tweibley@gmail.com with:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)

We will acknowledge receipt within 48 hours and work with you to understand and address the issue.

## Security Practices

This gem follows RubyGems security best practices:

- **MFA Required**: All gem owners must have MFA enabled
- **Trusted Publishing**: Releases use OIDC authentication (no long-lived API keys)
- **Checksums**: SHA512 checksums are published with each release
- **Dependency Scanning**: We use `bundle audit` to check for vulnerable dependencies

## Verifying Releases

You can verify the integrity of a release:

```bash
# Fetch the gem
gem fetch jules-ruby -v VERSION

# Compare checksum with the one published in GitHub Releases
ruby -rdigest/sha2 -e "puts Digest::SHA512.hexdigest(File.read('jules-ruby-VERSION.gem'))"
```
