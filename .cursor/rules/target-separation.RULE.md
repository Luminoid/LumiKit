---
description: "LumiKit three-target architecture: Core (Foundation), UI (UIKit+SnapKit), Lottie"
alwaysApply: true
---

# Target Separation

## Three Targets — Strict Boundaries

| Target | Dependencies | Allowed Imports |
|--------|-------------|-----------------|
| **LumiKitCore** | Foundation only | `Foundation` — nothing else |
| **LumiKitUI** | LumiKitCore + SnapKit | `UIKit`, `SnapKit`, `LumiKitCore` |
| **LumiKitLottie** | LumiKitUI + Lottie | `Lottie`, `LumiKitUI`, `UIKit` |

## Rules

- **NEVER** import UIKit in LumiKitCore — it must be pure Foundation
- **NEVER** import Lottie in LumiKitUI — Lottie is isolated so apps can opt out
- **ALWAYS** place Foundation-only utilities in LumiKitCore (Logger, DateHelper, FormatHelper, URLValidator, ConcurrencyHelpers, FileUtil, String extensions)
- **ALWAYS** place UIKit components in LumiKitUI (DesignSystem, Components, Controls, Extensions, Photo, Haptics, Alerts, Animation)
- **ALWAYS** use SnapKit for Auto Layout in LumiKitUI — never `NSLayoutConstraint` directly

## Adding New Files

1. Ask: "Does this need UIKit?" → No → LumiKitCore; Yes → LumiKitUI
2. Ask: "Does this need Lottie?" → Yes → LumiKitLottie
3. Place in the appropriate subdirectory within the target
4. Update `CLAUDE.md` project structure if adding a new subdirectory
