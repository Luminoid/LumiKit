---
description: "LumiKit five-product architecture: Core (Foundation), UI (UIKit+SnapKit), Photo (PhotosUI), Debug (DEBUG-only), Lottie"
alwaysApply: true
---

# Target Separation

## Five Products, Strict Boundaries

| Product | Depends on | Allowed imports | Default isolation |
|---|---|---|---|
| **LumiKitCore** | Foundation | `Foundation`, `UniformTypeIdentifiers`, `Synchronization`, `os` | none (nonisolated) |
| **LumiKitUI** | Core + SnapKit | `UIKit`, `SnapKit`, `LumiKitCore`, `CoreImage`, `CoreLocation`, `Synchronization` | `MainActor` |
| **LumiKitPhoto** | Core + UI | + `Photos`, `PhotosUI`, `ImageIO` | `MainActor` |
| **LumiKitDebug** | Core + UI (iOS / Catalyst only) | `Foundation` for the logger; `UIKit` + `LumiKitUI` for the inspector screens | none |
| **LumiKitLottie** | UI + Lottie | + `Lottie` | `MainActor` |

## Rules

- **NEVER** import UIKit in LumiKitCore
- **NEVER** import PhotosUI / Photos in LumiKitUI; anything that needs them lives in LumiKitPhoto
- **NEVER** import Lottie outside LumiKitLottie
- **NEVER** import LumiKitDebug from another product; it is compiled only under `LMK_ENABLE_NETWORK_LOGGING` (debug configurations) and linked by apps under `#if DEBUG`
- **ALWAYS** place Foundation-only utilities in LumiKitCore (`LMKLogger`, `LMKDate`, `LMKDateFormat`, `LMKFormat`, `LMKFile`, `LMKConcurrency`, `LMKURLValidator`, the calendar value types, String / Collection / NSAttributedString extensions)
- **ALWAYS** place UIKit components in LumiKitUI (`DesignSystem`, `Components`, `Controls`, `Extensions`, `Alerts`, `Animation`, `Haptics`, `Share`, `Utilities`)
- **ALWAYS** use SnapKit for Auto Layout in UI targets; never `NSLayoutConstraint` directly
- Each product owns its `Resources/<locale>.lproj/Localizable.strings` and its `LMKLocalized` helper; strings never cross products

## Adding New Files

1. Needs UIKit? No → LumiKitCore. Yes → LumiKitUI
2. Needs Photos / PhotosUI? → LumiKitPhoto. Needs Lottie? → LumiKitLottie. Debug-only network tooling? → LumiKitDebug
3. Place it in the matching subdirectory (`Components/<Family>/` for multi-file components); mirror the path under `Tests/<Target>Tests/`
4. Update `.claude/CLAUDE.md` when adding a subdirectory, and the target's DocC catalog topics when adding a public type
