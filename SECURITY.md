# Security policy

## Supported versions

| Version | Supported |
|---|---|
| 1.x | Yes |
| 0.x | No. Upgrade with `docs/MIGRATION-1.0.md`. |

## Reporting a vulnerability

Please do not open a public issue for a vulnerability. When the repository's Security tab offers "Report a vulnerability", use that private form. Until it does, open a public issue titled "Security contact request" that names the affected product and nothing more, and the maintainer will reply with a private channel for the details.

Include the affected product (`LumiKitCore`, `LumiKitUI`, `LumiKitPhoto`, `LumiKitDebug`, `LumiKitLottie`), the version, and steps to reproduce.

You will get an acknowledgement within 7 days and a fix or a mitigation plan within 90 days of the report. Please keep the report private until a fix has shipped; the advisory credits the reporter unless asked otherwise.

## Scope notes

- `LumiKitDebug` captures HTTP traffic through a `URLProtocol` for debugging. Its code is compiled only when `LMK_ENABLE_NETWORK_LOGGING` is defined, which the package sets for debug configurations. Do not define it in a release build. The logger redacts credential headers (`Authorization`, `Cookie`, `Set-Cookie`, `X-API-Key`, `x-goog-api-key`, and other common API-key and token headers) and credential query items (`key`, `token`, `access_token`, `signature`, signed-URL parameters) by default, accepts a `hostFilter` allowlist, and intercepts nothing while disabled; captured payloads copied to the pasteboard expire. While logging is on, logged requests share the app's default cookie jar, cache, and credential storage, and a session's own authentication delegate is not consulted.
- `LMKURLValidator` is a literal host blocklist (loopback, private, link-local, carrier-grade NAT, multicast, unspecified, `localhost` and `*.localhost`, including shorthand, octal, and hex IPv4 spellings). It does not resolve names, so it cannot catch a DNS record that points at a private address; resolve and re-check at request time when that matters.
- `LMKLogger` writes to the unified logging system with `public` message privacy by default. Set `LMKLogger.messagePrivacy = .private` when messages may carry personal data.
- `LMKPhotoMetadata.write(date:coordinate:to:)` embeds a capture date and location into image bytes on request; the caller decides whether location data may leave the device.
