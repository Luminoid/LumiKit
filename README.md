# LumiKit

Shared Swift Package providing **design tokens**, **UI components**, and **utilities** for Lumi apps. Built with Swift 6.2 strict concurrency, UIKit + SnapKit, and a fully configurable theming system.

---

## Table of Contents

1. [Overview](#overview)
2. [Requirements](#requirements)
3. [Installation](#installation)
4. [Quick Start](#quick-start)
5. [Package Structure](#package-structure)
6. [Design System](#design-system)
7. [Components](#components)
8. [Controls](#controls)
9. [Extensions](#extensions)
10. [Core Utilities](#core-utilities)
11. [Photo](#photo)
12. [Error Handling](#error-handling)
13. [Build & Test](#build--test)
14. [Dependencies](#dependencies)

---

## Overview

LumiKit is organized into three targets so apps can import only what they need:

| Target | Dependencies | Purpose |
|--------|-------------|---------|
| **LumiKitCore** | Foundation only | Logger, date helpers, URL validation, format helpers, file utilities, concurrency helpers, collection/string extensions |
| **LumiKitUI** | LumiKitCore + SnapKit | Design system tokens, theme manager, animation, haptics, alerts, components, controls, photo browser/crop, UIKit extensions |
| **LumiKitLottie** | LumiKitUI + Lottie | Lottie-powered pull-to-refresh control |

**73 source files** across 3 targets, with **167 tests** (56 Core + 111 UI) across 45 suites.

---

## Requirements

- Swift 6.2+
- iOS 18+ / Mac Catalyst 18+ / macOS 15+
- Xcode 26+

---

## Installation

Add LumiKit to your project via Swift Package Manager:

```swift
dependencies: [
    .package(path: "../LumiKit")  // Local package
    // or
    .package(url: "https://github.com/user/LumiKit.git", from: "1.0.0")
]
```

Then add the targets you need:

```swift
.target(
    name: "MyApp",
    dependencies: [
        "LumiKitCore",   // Foundation utilities only
        "LumiKitUI",     // Full design system + components
        "LumiKitLottie", // Optional: Lottie pull-to-refresh
    ]
)
```

---

## Quick Start

```swift
import LumiKitUI

// 1. Configure the theme at app launch
LMKThemeManager.shared.configure(
    colors: MyAppTheme(),
    typography: .init(fontFamily: "Inter"),
    spacing: .init(large: 20, xxl: 28),
    cornerRadius: .init(small: 12, medium: 16)
)

// 2. Use design tokens throughout your app
let label = LMKLabelFactory.title("Hello")
view.backgroundColor = LMKColor.backgroundPrimary

// 3. Use components
let toast = LMKToastView()
toast.show(message: "Saved!", in: view)

let emptyState = LMKEmptyStateView()
emptyState.configure(icon: UIImage(systemName: "leaf"), title: "No Plants", message: "Add your first plant")
```

---

## Package Structure

```
LumiKit/
├── Package.swift
├── Sources/
│   ├── LumiKitCore/
│   │   ├── Concurrency/       # LMKConcurrencyHelpers (encode/decode off main)
│   │   ├── Data/              # LMKFormatHelper, LMKLogger, Collection+LMK,
│   │   │                      # NSAttributedString+LMK, String+LMK
│   │   ├── Date/              # LMKDateHelper, LMKDateFormatterHelper
│   │   ├── File/              # LMKFileUtil
│   │   └── Validation/        # LMKURLValidator
│   ├── LumiKitUI/
│   │   ├── Alerts/            # LMKAlertPresenter, LMKErrorHandler
│   │   ├── Animation/         # LMKAnimationHelper, LMKAnimationTheme
│   │   ├── Components/        # EmptyState, Toast, SearchBar, Badge, Chip,
│   │   │                      # Divider, Gradient, Card, Banner, Skeleton, etc.
│   │   ├── Controls/          # Button, SegmentedControl, ToggleButton,
│   │   │                      # TextField, TextView
│   │   ├── DesignSystem/      # Token enums, theme configs, factories
│   │   ├── Extensions/        # UIKit extensions (lmk_ prefix)
│   │   ├── Haptics/           # LMKHapticFeedbackHelper
│   │   ├── Photo/             # LMKPhotoBrowserViewController, LMKPhotoCropViewController
│   │   └── Utilities/         # LMKDeviceHelper, LMKKeyboardObserver
│   └── LumiKitLottie/         # LMKLottieRefreshControl
├── Tests/
│   ├── LumiKitCoreTests/      # 56 tests (9 suites)
│   └── LumiKitUITests/        # 111 tests (36 suites)
```

---

## Design System

All design tokens are fully configurable via `LMKThemeManager`. Each category has a configuration struct with sensible defaults. Token enums proxy to the active configuration at runtime.

### Token Categories

| Category | Token Enum | Config Struct | Examples |
|----------|-----------|---------------|----------|
| Colors | `LMKColor` | `LMKTheme` (protocol) | `.primary`, `.backgroundPrimary`, `.textPrimary` |
| Typography | `LMKTypography` | `LMKTypographyTheme` | `fontFamily`, `h1Size`, `bodySize`, line heights |
| Spacing | `LMKSpacing` | `LMKSpacingTheme` | `.xs` (4pt), `.small` (8pt), `.medium` (12pt), `.large` (16pt) |
| Corner Radius | `LMKCornerRadius` | `LMKCornerRadiusTheme` | `.small` (8), `.medium` (12), `.large` (16) |
| Alpha | `LMKAlpha` | `LMKAlphaTheme` | `.overlay`, `.disabled`, `.overlayStrong` |
| Layout | `LMKLayout` | `LMKLayoutTheme` | `.minimumTouchTarget` (44), `.iconMedium` (24) |
| Shadow | `LMKShadow` | `LMKShadowTheme` | `cellCard()`, `card()`, `button()`, `small()` |
| Animation | `LMKAnimationHelper` | `LMKAnimationTheme` | `.Duration.*`, `.Spring.damping`, `.shouldAnimate` |
| Badge | `LMKBadgeView` | `LMKBadgeTheme` | `minWidth`, `height`, `horizontalPadding` |

### Configuration

```swift
// Configure everything at once
LMKThemeManager.shared.configure(
    colors: MyAppTheme(),
    typography: .init(fontFamily: "Inter"),
    spacing: .init(large: 20, xxl: 28),
    cornerRadius: .init(small: 12, medium: 16)
)

// Or configure individual categories
LMKThemeManager.shared.apply(MyAppTheme())
LMKThemeManager.shared.apply(typography: .init(fontFamily: "Inter"))
LMKThemeManager.shared.apply(spacing: .init(large: 20))
```

### Architecture: Token Enum → Config Struct → ThemeManager

```swift
// 1. Config struct with defaults (nonisolated, Sendable — safe from any context)
public nonisolated struct LMKSpacingTheme: Sendable {
    public var large: CGFloat
    public init(large: CGFloat = 16, ...) { ... }
}

// 2. Token enum proxies to active config (@MainActor)
public enum LMKSpacing {
    private static var config: LMKSpacingTheme { LMKThemeManager.shared.spacing }
    public static var large: CGFloat { config.large }
}

// 3. ThemeManager holds the active config
LMKThemeManager.shared.apply(spacing: .init(large: 20))
```

### Factories

| Factory | Purpose |
|---------|---------|
| `LMKButtonFactory` | Pre-styled buttons (primary, secondary, destructive) |
| `LMKCardFactory` | Card views with shadow and corner radius |
| `LMKLabelFactory` | Styled labels (title, subtitle, body, caption) |

---

## Components

| Component | Purpose |
|-----------|---------|
| `LMKBadgeView` | Notification count, status dot, or custom text badge |
| `LMKBannerView` | Persistent notification bar with optional action and dismiss |
| `LMKCardView` | Card container with shadow, corner radius, content insets |
| `LMKChipView` | Tag/filter chip (`.filled` / `.outlined`) with optional tap handler |
| `LMKDividerView` | Pixel-perfect separator (horizontal / vertical) |
| `LMKEmptyStateView` | Empty state with icon, title, message, action button |
| `LMKEnumSelectionBottomSheet` | Bottom sheet for selecting from an enum's cases |
| `LMKGradientView` | `CAGradientLayer`-backed view with 4 direction options |
| `LMKLoadingStateView` | Loading indicator with optional message |
| `LMKProgressViewController` | Progress indicator view controller |
| `LMKSearchBar` | Search bar with configurable placeholder and cancel text |
| `LMKSkeletonCell` | Skeleton loading placeholder cell |
| `LMKToastView` | Auto-dismissing toast notification |

---

## Controls

| Control | Purpose |
|---------|---------|
| `LMKButton` | Configurable button with tap handler and multiple styles |
| `LMKSegmentedControl` | Custom segmented control |
| `LMKTextField` | Text field with validation states, helper text, leading icon |
| `LMKTextView` | Multi-line text input with placeholder and character limit |
| `LMKToggleButton` | Toggle button with on/off states |

---

## Extensions

All UIKit extensions use the `lmk_` prefix to avoid naming conflicts.

| Extension | Key Methods |
|-----------|-------------|
| `UIColor+LMK` | `init(lmk_hex:)`, `lmk_hexString`, `lmk_isLight`, `lmk_adjustedBrightness(by:)`, `lmk_contrastingTextColor` |
| `UIImage+LMK` | `lmk_resized(maxDimension:)`, `lmk_resized(to:)`, `lmk_solidColor(_:size:)`, `lmk_rounded(cornerRadius:)` |
| `UIView+LMKShadow` | `lmk_applyShadow(_:)`, `lmk_removeShadow()` |
| `UIView+LMKBorder` | `lmk_applyBorder(...)`, `lmk_removeBorder()`, `lmk_applyCornerRadius(_:)`, `lmk_makeCircular()` |
| `UIView+LMKFade` | `lmk_fadeIn(...)`, `lmk_fadeOut(...)` |
| `UIView+LMKLayout` | `lmk_addSubviews(...)`, `lmk_pinToEdges(...)` |
| `UIStackView+LMK` | `init(lmk_axis:...)`, `lmk_addArrangedSubviews(_:)`, `lmk_removeAllArrangedSubviews()` |
| `UIButton+LMKAnimation` | Tap animation helpers |
| `UIControl+LMKTouchArea` | Expanded touch area support |
| `UITableViewCell+LMKHighlight` | Custom highlight behavior |
| `UITextField+LMKFormStyle` | Form-styled text field configuration |
| `UIViewController+LMKOrientation` | Orientation lock helpers |
| `UIViewController+LMKPopover` | Popover presentation helpers |
| `UIViewController+LMKTopViewController` | Top view controller traversal |

---

## Core Utilities

LumiKitCore provides Foundation-only utilities with zero dependencies:

| Utility | Purpose |
|---------|---------|
| `LMKLogger` | Structured logging with categories (`.general`, `.data`, `.ui`, `.network`, `.error`) |
| `LMKDateHelper` | Date calculation, comparison, and formatting helpers |
| `LMKDateFormatterHelper` | Cached date formatters for performance |
| `LMKFormatHelper` | Number and string formatting utilities |
| `LMKFileUtil` | File system operations |
| `LMKURLValidator` | URL validation and sanitization |
| `LMKConcurrencyHelpers` | Off-main-thread Codable encode/decode |
| `Collection+LMK` | Safe subscript, grouping, and collection utilities |
| `String+LMK` | String manipulation and validation extensions |
| `NSAttributedString+LMK` | Attributed string building helpers |

---

## Photo

| Component | Purpose |
|-----------|---------|
| `LMKPhotoBrowserViewController` | Full-screen photo browser with zoom and swipe navigation |
| `LMKPhotoCropViewController` | Photo cropping with aspect ratio support |

---

## Error Handling

`LMKErrorHandler` provides severity-based error presentation:

| Severity | Behavior |
|----------|----------|
| `.info` | Info toast |
| `.warning` | Alert with OK |
| `.error` | Toast (transient) or alert with retry (recoverable) |
| `.critical` | Always alert, retry if available |

All presentation methods auto-log via `LMKLogger`. Use `LMKAlertPresenter` for generic alerts and action sheets.

---

## Build & Test

```bash
# Build all targets (iOS Simulator)
xcodebuild build \
  -scheme LumiKit-Package \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -skipPackagePluginValidation \
  CODE_SIGNING_ALLOWED=NO

# Build for Mac Catalyst
xcodebuild build \
  -scheme LumiKit-Package \
  -destination 'platform=macOS,variant=Mac Catalyst' \
  -skipPackagePluginValidation \
  CODE_SIGNING_ALLOWED=NO

# Run tests (requires iOS Simulator — UIKit targets can't use swift test)
xcodebuild test \
  -scheme LumiKit-Package \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -skipPackagePluginValidation \
  CODE_SIGNING_ALLOWED=NO

# Build single target (faster iteration)
swift build --target LumiKitCore
```

---

## Dependencies

| Library | Version | Target | Purpose |
|---------|---------|--------|---------|
| [SnapKit](https://github.com/SnapKit/SnapKit) | 5.7.0+ | LumiKitUI | Programmatic Auto Layout |
| [Lottie](https://github.com/airbnb/lottie-ios) | 4.4.0+ | LumiKitLottie | Pull-to-refresh animation |

Lottie is isolated in its own target so apps can opt out if they don't need pull-to-refresh animations.

---

## Naming Conventions

- **Public types**: `LMK` prefix (e.g., `LMKColor`, `LMKSpacing`, `LMKAnimationHelper`)
- **Extension methods**: `lmk_` prefix (e.g., `view.lmk_addSubviews(...)`)
- **Theme configs**: `LMK*Theme` structs (e.g., `LMKTypographyTheme`, `LMKSpacingTheme`)
- **Protocols**: `LMK*DataSource`, `LMK*Delegate`

---

## Concurrency

LumiKitUI and LumiKitLottie use Swift 6.2 `defaultIsolation: MainActor` — all types are `@MainActor` by default. Pure data types (theme config structs) opt out with `nonisolated` and conform to `Sendable` so they can be created and passed from any context.

LumiKitCore has no default isolation and is safe to use from any concurrency context.
