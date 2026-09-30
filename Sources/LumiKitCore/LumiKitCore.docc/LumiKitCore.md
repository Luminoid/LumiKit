# ``LumiKitCore``

Foundation-only utilities shared by every LumiKit product and usable from any target: logging, dates and formatting, files, concurrency helpers, URL validation, and calendar value types.

## Overview

`LumiKitCore` has no UIKit dependency and no default actor isolation, so every API is callable from any isolation context. It builds natively for macOS as well as for iOS and Mac Catalyst. Strings it shows (relative day names, ongoing ranges) ship in English, Spanish, Simplified Chinese, and Traditional Chinese.

```swift
import LumiKitCore

LMKLogger.configure(subsystem: Bundle.main.bundleIdentifier ?? "app")
LMKLogger.minimumLevel = .info
LMKLogger.info("Launched", category: .general)

let label = LMKDateFormat.string(date, date: .medium, time: .short)
let range = LMKDateFormat.rangeLabel(start: trip.start, end: trip.end)
let today = LMKCalendarDay.today()
```

## Topics

### Logging

- ``LMKLogger``
- ``LMKLogging``
- ``LMKLogLevel``
- ``LMKLogEntry``
- ``LMKLogStore``

### Dates

- ``LMKDate``
- ``LMKDateFormat``
- ``LMKCalendarDay``
- ``LMKCalendarMonth``
- ``LMKCalendarSelection``
- ``LMKCalendarSelectionMode``

### Formatting, files, and concurrency

- ``LMKFormat``
- ``LMKFile``
- ``LMKConcurrency``

### Validation

- ``LMKURLValidator``
