# ``LumiKitCore``

Foundation-only utilities shared by every LumiKit product and usable from any target: logging, dates and formatting, files, concurrency helpers, URL validation, and calendar value types.

## Overview

`LumiKitCore` has no UIKit dependency and no default actor isolation, so every API is callable from any isolation context. It builds natively for macOS as well as for iOS and Mac Catalyst. The one string it supplies itself (the ongoing-range format) ships in English, Spanish, Simplified Chinese, and Traditional Chinese; relative day names come from the system formatter in any locale. `LumiKitUI` links this module but does not re-export it, so a file that names a Core type imports `LumiKitCore`.

```swift
import LumiKitCore

LMKLogger.configure(subsystem: Bundle.main.bundleIdentifier ?? "app")
LMKLogger.minimumLevel = .info
LMKLogger.info("Launched", category: .general)

let label = LMKDateFormat.string(date, date: .medium, time: .short)
let range = LMKDateFormat.rangeLabel(start: trip.start, end: trip.end)
let today = LMKCalendarDay.today()
```

## Calendar days are Gregorian civil dates

``LMKCalendarDay`` and ``LMKCalendarMonth`` are civil dates in the Gregorian calendar whatever `Calendar` you pass: under the Japanese, Buddhist, Chinese, or Hebrew calendar a day keeps the same year, month, day, and `key`. Component math goes through `Calendar.lmk_civilCalendar`, a Gregorian twin of the supplied calendar with the same time zone, locale, first weekday, and minimum days in the first week. Day and month deltas (`days(to:)`, `adding(days:)`, `months(to:)`) anchor both ends at noon, so a daylight-saving change at midnight cannot shift them. To show a day, format it with `Calendar.lmk_civilDisplayCalendar`: the supplied calendar when its months are Gregorian months (`Calendar.lmk_hasGregorianMonths`: gregorian, iso8601, japanese, buddhist, republicOfChina), the twin otherwise. ``LMKCalendarSelection`` reads a `.range` built with its bounds reversed in chronological order.

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
