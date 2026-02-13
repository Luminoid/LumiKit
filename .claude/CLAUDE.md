# LumiKit — Claude Code Guide

> Shared Swift Package providing design tokens, UI components, and utilities for Lumi apps.

---

## Package Overview

| Target | Dependencies | Purpose |
|--------|-------------|---------|
| **LumiKitCore** | Foundation only | Logger, DateHelper, URLValidator, ConcurrencyHelpers, FormatHelper, FileHelper, String extensions |
| **LumiKitUI** | LumiKitCore + SnapKit | Design system tokens, theme, animation, haptics, alerts, components, controls, photo browser/crop, extensions |
| **LumiKitLottie** | LumiKitUI + Lottie | Lottie-powered pull-to-refresh control |

**Swift 6.2** strict concurrency with `defaultIsolation: MainActor` on LumiKitUI and LumiKitLottie targets. Platforms: iOS 18+, Mac Catalyst 18+, macOS 15+.

---

## Project Structure

```
LumiKit/
├── Package.swift
├── Sources/
│   ├── LumiKitCore/
│   │   ├── Concurrency/     # LMKConcurrencyHelpers (encode/decode off main)
│   │   ├── Data/            # LMKFormatHelper
│   │   ├── Date/            # LMKDateHelper, LMKDateFormatterHelper
│   │   ├── File/            # LMKFileHelper
│   │   └── Validation/      # LMKURLValidator, String+LMK
│   ├── LumiKitUI/
│   │   ├── Alerts/          # LMKAlertPresenter
│   │   ├── Animation/       # LMKAnimationHelper
│   │   ├── Components/      # LMKEmptyStateView, LMKToastView, etc.
│   │   ├── Controls/        # LMKWaterButton, etc.
│   │   ├── DesignSystem/    # LMKColor, LMKTypography, LMKSpacing, LMKCornerRadius, LMKAlpha, LMKLayout, LMKShadow, LMKTheme
│   │   ├── Extensions/      # UIKit extensions (lmk_ prefix)
│   │   ├── Haptics/         # LMKHapticManager
│   │   └── Photo/           # LMKPhotoBrowserViewController, LMKPhotoCropViewController
│   └── LumiKitLottie/       # LMKLottieRefreshControl
├── Tests/
│   ├── LumiKitCoreTests/    # 44 tests (7 suites)
│   └── LumiKitUITests/      # 23 tests (9 suites)
```

---

## Naming Conventions

- **Public types**: `LMK` prefix (e.g. `LMKColor`, `LMKSpacing`, `LMKAnimationHelper`)
- **Extension methods**: `lmk_` prefix (e.g. `view.lmk_addSubviews(...)`)
- **Configurable strings**: Module-level `nonisolated(unsafe)` variable + `Sendable` struct
  ```swift
  public struct LMKPhotoCropStrings: Sendable { ... }
  nonisolated(unsafe) public var lmkPhotoCropStrings = LMKPhotoCropStrings()
  ```
- **Protocols for data/delegates**: `LMKPhotoBrowserDataSource`, `LMKPhotoCropDelegate`
- **View Controllers**: `LMK*ViewController`
- **Cells**: `LMK*Cell`

---

## Swift 6.2 Concurrency Patterns

- LumiKitUI and LumiKitLottie use `defaultIsolation: MainActor` — all types are MainActor by default (no explicit `@MainActor` needed)
- Pure data types (Sendable structs, protocols) must opt out with `nonisolated`
- Configurable strings accessed from non-MainActor contexts **must** be module-level `nonisolated(unsafe)` — not nested inside MainActor classes
- Use `Sendable` for all configuration structs
- `LMKConcurrencyHelpers.encode/decode` — off-main-thread Codable operations

---

## Design System Tokens

**Always use LMK tokens — never hardcode values.**

| Category | Enum | Examples |
|----------|------|---------|
| Colors | `LMKColor` | `.primary`, `.backgroundPrimary`, `.textPrimary` (proxied through `LMKTheme`) |
| Typography | `LMKTypography` | `.h1`, `.body`, `.caption` with line heights and letter spacing |
| Spacing | `LMKSpacing` | `.xs` (4pt), `.small` (8pt), `.medium` (12pt), `.large` (16pt), `.xl` (20pt), `.xxl` (24pt) |
| Corner Radius | `LMKCornerRadius` | `.small`, `.medium`, `.large` |
| Alpha | `LMKAlpha` | `.light`, `.medium`, `.heavy` |
| Layout | `LMKLayout` | `.minimumTouchTarget` (44pt), `.iconMedium` (24pt), `.pullThreshold` (80pt) |
| Shadow | `LMKShadow` | Shadow configurations |
| Animation | `LMKAnimationHelper` | `.Duration`, `.shouldAnimate`, `.Spring` |

### Theme System

```swift
// App configures theme at launch
LMKThemeManager.shared.apply(MyAppTheme())

// LMKColor proxies to current theme
view.backgroundColor = LMKColor.backgroundPrimary
```

---

## Build & Test Commands

```bash
# Build all targets (iOS Simulator)
xcodebuild build \
  -scheme LumiKit-Package \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -skipPackagePluginValidation \
  CODE_SIGNING_ALLOWED=NO 2>&1 | tail -5

# Build for Mac Catalyst
xcodebuild build \
  -scheme LumiKit-Package \
  -destination 'platform=macOS,variant=Mac Catalyst' \
  -skipPackagePluginValidation \
  CODE_SIGNING_ALLOWED=NO 2>&1 | tail -5

# Run tests (requires iOS Simulator — UIKit targets can't use `swift test`)
xcodebuild test \
  -scheme LumiKit-Package \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -skipPackagePluginValidation \
  CODE_SIGNING_ALLOWED=NO 2>&1 | tail -20

# Build single target (faster iteration)
swift build --target LumiKitCore
```

---

## Adding New Tokens / Components

1. **New design token**: Add to appropriate `LMK*` enum in `DesignSystem/`; update `LMKTheme` protocol if theme-dependent
2. **New component**: Add to `Components/` or `Controls/`; use `LMK` prefix; depend only on design tokens
3. **New extension**: Add to `Extensions/` with `lmk_` prefix; keep extensions small and focused
4. **New configurable strings**: Use the module-level pattern (not nested in `@MainActor` class)
5. **After changes**: Run full build on iOS Simulator + Mac Catalyst; run tests

---

## Dependencies

| Library | Version | Target | Purpose |
|---------|---------|--------|---------|
| SnapKit | 5.7.0+ | LumiKitUI | Programmatic Auto Layout |
| Lottie | 4.4.0+ | LumiKitLottie | Pull-to-refresh animation |

- **SnapKit**: Always use SnapKit for constraints; never use `NSLayoutConstraint` directly
- **Lottie**: Isolated in separate target so apps can opt out

---

*Optimized for Claude Code • Last updated: 2026-02-12*
