<p align="center">
  <img src="Example/Resources/Assets.xcassets/AppIcon.appiconset/app_icon.png" width="128" alt="LumiKit">
</p>

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
10. [Animation & Haptics](#animation--haptics)
11. [Core Utilities](#core-utilities)
12. [UI Utilities](#ui-utilities)
13. [Photo](#photo)
14. [Share](#share)
15. [QR Code](#qr-code)
16. [Error Handling](#error-handling)
17. [Build & Test](#build--test)
18. [Release](#release)
19. [Dependencies](#dependencies)
20. [Built with LumiKit](#built-with-lumikit)
21. [TODO](#todo)
22. [License](#license)
23. [Changelog](#changelog)

---

## Overview

LumiKit is organized into three targets so apps can import only what they need:

| Target | Dependencies | Purpose |
|--------|-------------|---------|
| **LumiKitCore** | Foundation only | Logger, date helpers, URL validation, format helpers, file utilities, concurrency helpers, collection/string extensions |
| **LumiKitUI** | LumiKitCore + SnapKit | Design system tokens, theme manager, animation, haptics, alerts, components, controls, photo browser/crop, UIKit extensions |
| **LumiKitLottie** | LumiKitUI + Lottie | Lottie-powered pull-to-refresh control |

**83 source files** across 3 targets, with **340 tests** (60 Core + 280 UI) across 74 suites.

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
    .package(url: "https://github.com/Luminoid/LumiKit.git", from: "0.1.0")
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
let label = LMKLabelFactory.heading(text: "Hello")
view.backgroundColor = LMKColor.backgroundPrimary

// 3. Use components
LMKToast.showSuccess(message: "Saved!", on: self)

let emptyState = LMKEmptyStateView()
emptyState.configure(message: "Nothing here yet", icon: "tray", style: .card)
```

---

## Example App

The `Example/` directory contains a full catalog app demonstrating every component. It uses [XcodeGen](https://github.com/yonaskolb/XcodeGen) to generate the Xcode project:

```bash
cd Example
xcodegen generate
open LumiKitExample.xcodeproj
```

The example includes 18 interactive pages: Typography, Colors, Cards, Badges, Chips, Empty State, Buttons, Toast, Controls, Gradient, Loading State, Banner, Action Sheet, QR Code, Photo Browser, Photo Crop, User Tip, and Floating Button.

---

## Package Structure

```
LumiKit/
├── Package.swift
├── Sources/
│   ├── LumiKitCore/
│   │   ├── Concurrency/       # LMKConcurrencyHelpers (encode/decode off main)
│   │   ├── Data/              # LMKFormatHelper, Collection+LMK,
│   │   │                      # NSAttributedString+LMK, String+LMK
│   │   ├── Date/              # LMKDateHelper, LMKDateFormatterHelper
│   │   ├── File/              # LMKFileUtil
│   │   ├── Log/               # LMKLogger, LMKLogStore (ring buffer),
│   │   │                      # LMKLogLevel, LMKLogEntry
│   │   └── Validation/        # LMKURLValidator
│   ├── LumiKitUI/
│   │   ├── Alerts/            # LMKAlertPresenter, LMKErrorHandler
│   │   ├── Animation/         # LMKAnimationHelper, LMKAnimationTheme
│   │   ├── Components/
│   │   │   ├── BottomSheet/   # LMKBottomSheetController (base), LMKActionSheet,
│   │   │   │                  # LMKEnumSelectionBottomSheet, LMKBottomSheetLayout
│   │   │   ├── Pickers/       # LMKDatePickerHelper
│   │   │   ├── LMKBadgeView, LMKBannerView, LMKCardView, LMKChipView,
│   │   │   ├── LMKDividerView, LMKEmptyStateView, LMKFloatingButton,
│   │   │   ├── LMKGradientView, LMKLoadingStateView, LMKProgressViewController,
│   │   │   └── LMKSearchBar, LMKSkeletonCell, LMKToastView, LMKUserTipView
│   │   ├── Controls/          # LMKButton, LMKSegmentedControl, LMKToggleButton,
│   │   │                      # LMKTextField, LMKTextView
│   │   ├── DesignSystem/
│   │   │   ├── Tokens/        # LMKColor, LMKSpacing, LMKCornerRadius, LMKAlpha,
│   │   │   │                  # LMKLayout, LMKShadow, LMKTypography
│   │   │   ├── Themes/        # LMKSpacingTheme, LMKCornerRadiusTheme, LMKAlphaTheme,
│   │   │   │                  # LMKLayoutTheme, LMKShadowTheme, LMKTypographyTheme,
│   │   │   │                  # LMKBadgeTheme
│   │   │   ├── Factories/     # LMKButtonFactory, LMKCardFactory, LMKLabelFactory
│   │   │   └── LMKTheme.swift # LMKTheme protocol + LMKThemeManager + LMKDefaultTheme
│   │   ├── Extensions/        # UIKit extensions (lmk_ prefix)
│   │   ├── Haptics/           # LMKHapticFeedbackHelper
│   │   ├── Photo/             # LMKPhotoBrowserViewController, LMKPhotoBrowserCell,
│   │   │                      # LMKPhotoCropViewController, LMKPhotoEXIFService,
│   │   │                      # LMKPhotoBrowserConfig
│   │   ├── QRCode/            # LMKQRCodeGenerator
│   │   ├── Share/             # LMKShareService, LMKSharePreviewViewController
│   │   └── Utilities/         # LMKDeviceHelper, LMKKeyboardObserver,
│   │                          # LMKSceneUtil, LMKImageUtil
│   └── LumiKitLottie/         # LMKLottieRefreshControl
├── Tests/
│   ├── LumiKitCoreTests/      # 77 tests, 12 suites
│   │   ├── Concurrency/       # LMKConcurrencyHelpers
│   │   ├── Data/              # String+LMK, Collection+LMK, NSAttributedString+LMK, FormatHelper
│   │   ├── Date/              # DateHelper, DateFormatterHelper
│   │   ├── File/              # FileUtil
│   │   ├── Log/               # LMKLogStore (ring buffer, thread safety),
│   │   │                      # LMKLogger (log store integration)
│   │   └── Validation/        # URLValidator
│   └── LumiKitUITests/        # 243+ tests, 61+ suites
│       ├── Alerts/            # AlertPresenter, ErrorHandler
│       ├── Animation/         # AnimationHelper
│       ├── Components/
│       │   ├── BottomSheet/   # BottomSheetController, ActionSheet, BottomSheetLayout
│       │   ├── Pickers/       # DatePickerHelper
│       │   ├── Badge, Banner, Card, Chip, Divider, EmptyState,
│       │   └── Gradient, LoadingState, SearchBar, Skeleton, Toast
│       ├── Controls/          # Button, SegmentedControl, TextField, TextView, ToggleButton
│       ├── DesignSystem/
│       │   ├── Tokens/        # Color, Spacing, CornerRadius, Alpha, Typography, Layout, Shadow
│       │   ├── Themes/        # AnimationTheme, BadgeTheme, SendableCompliance
│       │   ├── Factories/     # ButtonFactory, CardFactory, LabelFactory
│       │   └── ThemeManager, ComponentToken integration
│       ├── Extensions/        # UIColor, UIImage, UIStackView,
│       │                      # UIView (shadow/border/fade/layout)
│       ├── Photo/             # CropAspectRatio, PhotoEXIF
│       ├── QRCode/            # QRCodeGenerator
│       ├── Share/             # SharePreview, ShareService
│       └── Utilities/         # DeviceHelper, ImageUtil, KeyboardObserver
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
| `LMKBottomSheetController` | Base class for bottom sheet presentation with shared dimming, container, animation, and dismiss |
| `LMKActionSheet` | Custom bottom-sheet action sheet with design-token styling and optional custom content |
| `LMKBadgeView` | Notification count, status dot, or custom text badge |
| `LMKBannerView` | Persistent notification bar with optional action and dismiss |
| `LMKCardView` | Card container with shadow, corner radius, content insets |
| `LMKChipView` | Tag/filter chip (`.filled` / `.outlined`) with optional tap handler |
| `LMKDividerView` | Pixel-perfect separator (horizontal / vertical) |
| `LMKEmptyStateView` | Empty state with icon, title, message, action button |
| `LMKEnumSelectionBottomSheet` | Bottom sheet for selecting from an enum's cases |
| `LMKGradientView` | `CAGradientLayer`-backed view with 4 direction options |
| `LMKLoadingStateView` | Loading indicator with optional message |
| `LMKProgressViewController` | Blocking progress modal (`.determinate` with progress bar, `.indeterminate` spinner-only) |
| `LMKSearchBar` | Search bar with configurable placeholder and cancel text |
| `LMKSkeletonCell` | Skeleton loading placeholder cell |
| `LMKDatePickerHelper` | Date picker presentation via `LMKActionSheet` — single date, date range, date with text field |
| `LMKToastView` | Auto-dismissing toast notification |
| `LMKUserTipView` | Onboarding tip with centered or pointed (arrow) styles — tap to dismiss |
| `LMKFloatingButton` | Draggable floating action button with edge snapping and optional badge |

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
| `UIView+LMKLayout` | `lmk_safeAreaSnp`, `lmk_setEdgesEqualToSuperView()`, `lmk_setAutoLayoutSize(width:height:)` |
| `UIStackView+LMK` | `init(lmk_axis:...)`, `lmk_addArrangedSubviews(_:)`, `lmk_removeAllArrangedSubviews()` |
| `UIButton+LMKAnimation` | Tap animation helpers |
| `UIControl+LMKTouchArea` | Expanded touch area support |
| `UITableViewCell+LMKHighlight` | Custom highlight behavior |
| `UITextField+LMKFormStyle` | Form-styled text field configuration |
| `UIViewController+LMKOrientation` | Orientation lock helpers |
| `UIViewController+LMKPopover` | Popover presentation helpers |
| `UIViewController+LMKTopViewController` | Top view controller traversal |

---

## Animation & Haptics

| Utility | Purpose |
|---------|---------|
| `LMKAnimationHelper` | Centralized animation timing with Reduce Motion support (`shouldAnimate`), spring damping, and duration presets |
| `LMKAnimationTheme` | Configurable animation token struct (durations, spring parameters) via `LMKThemeManager` |
| `LMKHapticFeedbackHelper` | Haptic feedback helpers — light, medium, heavy impact and success/error notification feedback |

---

## Core Utilities

LumiKitCore provides Foundation-only utilities with zero dependencies:

| Utility | Purpose |
|---------|---------|
| `LMKLogger` | Structured logging with categories (`.general`, `.data`, `.ui`, `.network`, `.error`) and opt-in in-memory log store (`LMKLogStore`) |
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

## UI Utilities

LumiKitUI includes device-aware helpers and system observers:

| Utility | Purpose |
|---------|---------|
| `LMKDeviceHelper` | Device type detection (`.iPhone`, `.iPad`, `.macCatalyst`), screen size classification, notch detection |
| `LMKKeyboardObserver` | Keyboard show/hide observer with height and animation duration info |
| `LMKImageUtil` | SF Symbol creation and `CVPixelBuffer` to JPEG conversion |
| `LMKSceneUtil` | Key window and connected scene retrieval |

---

## Photo

| Component | Purpose |
|-----------|---------|
| `LMKPhotoBrowserViewController` | Full-screen photo browser with zoom and swipe navigation |
| `LMKPhotoCropViewController` | Photo cropping with aspect ratio support |
| `LMKPhotoEXIFService` | EXIF date and GPS extraction from UIImage or PHPickerResult |

Both photo view controllers force dark mode (`overrideUserInterfaceStyle = .dark`) and set `preferredStatusBarStyle = .lightContent`. They handle `modalPresentationCapturesStatusBarAppearance` automatically, so the status bar is correct when presented modally. If you embed them in a `UINavigationController`, override `childForStatusBarStyle` on the nav controller to return `topViewController`.

---

## Share

| Component | Purpose |
|-----------|---------|
| `LMKShareService` | Share sheet wrapper with `shareImage`, `shareFile` and popover support |
| `LMKSharePreviewViewController` | Image preview sheet with share and save-to-photos actions |

---

## QR Code

| Component | Purpose |
|-----------|---------|
| `LMKQRCodeGenerator` | CoreImage QR code generation with configurable correction level and size |

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

## Release

To publish a new version:

```bash
# 1. Update CHANGELOG.md with the new version and date
# 2. Commit all changes
git add CHANGELOG.md README.md
git commit -m "docs: prepare vX.Y.Z release"

# 3. Tag the release
git tag X.Y.Z
git push origin main --tags

# 4. Create GitHub release
gh release create X.Y.Z --title "X.Y.Z" --notes "Release notes here"
```

Version tags follow [Semantic Versioning](https://semver.org): `MAJOR.MINOR.PATCH`. Swift Package Manager resolves versions from git tags — no version field in `Package.swift`.

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

---

## Built with LumiKit

| App | Description |
|-----|-------------|
| [Plantfolio Plus](https://luminoid.github.io/plantfolio-site) | Plant care, watering schedules, collections, and photos for iOS, iPadOS, and Mac |

---

## TODO

- [ ] Create CONTRIBUTING.md with contribution guidelines
- [ ] Set up GitHub Actions CI (test on push/PR — iOS Simulator + Mac Catalyst)
- [ ] Add SECURITY.md
- [ ] Add DocC API reference documentation
- [ ] Register on [Swift Package Index](https://swiftpackageindex.com)

---

## License

LumiKit is released under the MIT License. See [LICENSE](LICENSE) for details.

---

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for a detailed history of changes.
