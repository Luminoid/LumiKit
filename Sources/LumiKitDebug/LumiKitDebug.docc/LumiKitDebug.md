# ``LumiKitDebug``

Network capture through a `URLProtocol` and an inspector for the captured requests, for debug builds.

## Overview

Every file of the product is compiled only when `LMK_ENABLE_NETWORK_LOGGING` is defined, which the package sets for debug configurations. Link it under `#if DEBUG` and never define the flag in a release build. The logger is Foundation-only and builds natively for macOS; the inspector screens need UIKit.

```swift
#if DEBUG
import LumiKitDebug

LMKNetworkLogger.configure(LMKNetworkLogger.Configuration(maxRecords: 200, hostFilter: ["api.example.com"]))
LMKNetworkLogger.enable()
let session = URLSession(configuration: URLSessionConfiguration.default.lmk_enableNetworkLogging())

// From a debug menu:
navigationController.pushViewController(LMKNetworkHistoryViewController(), animated: true)
#endif
```

Credentials never reach the store. By default the `Authorization`, `Cookie`, `Set-Cookie`, `X-API-Key`, `api-key`, `x-goog-api-key`, `x-access-token`, `x-amz-security-token`, CSRF / XSRF, and Azure key headers (`redactedHeaderFields`) and the `key`, `token`, `access_token`, `signature`, `client_secret`, signed-URL, and similar query items (`redactedQueryItems`) are replaced at capture time, in the request URL, in a `Location` header, and in a URL's password; `redact(_:configuration:)` applies the same rules to a URL of your own. A disabled logger intercepts nothing, even on a session that lists it, and only `http` / `https` requests are captured.

Request bodies are captured, streamed ones included when they carry a `Content-Length`; bodies are capped, and `isBodyTruncated` on the request and response says when the cap cut one. `recordsDidChangeNotification` fires as records arrive and `record(id:)` reads one back.

A logged request runs on the logger's own session: one shared `.default` configuration, so the shared cookie jar, cache, and credential storage keep working while logging is on. The request arrives with your session's `httpAdditionalHeaders` already applied. Redirects are reported back to your session, which decides whether to follow them, and both hops are recorded. While logging is on a refused redirect completes about half a second later: the logger holds the 3xx response until your session has decided. What does not carry over: a session's own cookie storage, cache, credential storage, and timeouts, and its delegate's authentication handling (certificate pinning, client certificates), which the system's default handling answers instead.

Each record's `outcome` is pending, success (a 2xx response, or 304 Not Modified), redirect (any other 3xx), or error (a failed request, or any other status). The history screen is a diffable list on LumiKit rows that marks each outcome with its own glyph, so a followed redirect never reads as a failure; the detail screen, localized like the rest of the kit, copies headers and bodies to a pasteboard entry that expires.

## Topics

### Capture

- ``LMKNetworkLogger``
- ``LMKNetworkRequestRecord``

### Inspector

- ``LMKNetworkHistoryViewController``
