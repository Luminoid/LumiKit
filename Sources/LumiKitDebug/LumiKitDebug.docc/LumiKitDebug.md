# ``LumiKitDebug``

Network capture through a `URLProtocol` and an inspector for the captured requests, for debug builds.

## Overview

The whole product is compiled only when `LMK_ENABLE_NETWORK_LOGGING` is defined, which the package sets for debug configurations. Link it under `#if DEBUG` and never define the flag in a release build. The logger is Foundation-only and builds natively for macOS; the inspector screens need UIKit.

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

`Authorization`, `Cookie`, `Set-Cookie`, and `X-API-Key` headers are redacted by default (`redactedHeaderFields`), bodies are capped, and `recordsDidChangeNotification` fires as records arrive. The history screen is a diffable list on LumiKit rows; the detail screen copies headers and bodies to a pasteboard entry that expires.

## Topics

### Capture

- ``LMKNetworkLogger``
- ``LMKNetworkRequestRecord``

### Inspector

- ``LMKNetworkHistoryViewController``
