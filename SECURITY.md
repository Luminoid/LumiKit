# Security policy

## Supported versions

| Version | Supported |
|---|---|
| 1.x | Yes |
| 0.x | No. Upgrade with `docs/MIGRATION-1.0.md`. |

## Reporting a vulnerability

Report privately through GitHub's private vulnerability reporting on the repository (Security tab, "Report a vulnerability"). Include the affected product (`LumiKitCore`, `LumiKitUI`, `LumiKitPhoto`, `LumiKitDebug`, `LumiKitLottie`), the version, and steps to reproduce.

You will get an acknowledgement within 7 days and a fix or a mitigation plan within 90 days of the report. Please keep the report private until a fix has shipped; the advisory credits the reporter unless asked otherwise.

## Scope notes

- `LumiKitDebug` captures HTTP traffic through a `URLProtocol` for debugging. Its code is compiled only when `LMK_ENABLE_NETWORK_LOGGING` is defined, which the package sets for debug configurations. Do not define it in a release build. The logger redacts `Authorization`, `Cookie`, `Set-Cookie`, and `X-API-Key` headers by default and accepts a `hostFilter` allowlist; captured payloads copied to the pasteboard expire.
- `LMKURLValidator` is a literal host blocklist (loopback, private, link-local, carrier-grade NAT, multicast, unspecified). It does not resolve names, so it cannot catch a DNS record that points at a private address; resolve and re-check at request time when that matters.
- `LMKLogger` writes to the unified logging system with `public` message privacy by default. Set `LMKLogger.messagePrivacy = .private` when messages may carry personal data.
- `LMKPhotoMetadata.write(date:coordinate:to:)` embeds a capture date and location into image bytes on request; the caller decides whether location data may leave the device.
