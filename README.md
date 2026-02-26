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
17. [Debug Tools](#debug-tools-debug-builds-only)
18. [Build & Test](#build--test)
19. [Release](#release)
20. [Dependencies](#dependencies)
21. [Built with LumiKit](#built-with-lumikit)
22. [TODO](#todo)
23. [License](#license)
24. [Changelog](#changelog)

---

## Overview

LumiKit is organized into four targets so apps can import only what they need:

| Target | Dependencies | Purpose |
|--------|-------------|---------|
| **LumiKitCore** | Foundation only | Logger, date helpers, URL validation, format helpers, file utilities, concurrency helpers, collection/string extensions |
| **LumiKitNetwork** | LumiKitCore | Network debugging with URLProtocol interception (DEBUG only, Swift 6 concurrency compatible) |
| **LumiKitUI** | LumiKitCore + LumiKitNetwork + SnapKit | Design system tokens, theme manager, animation, haptics, alerts, components, controls, photo browser/crop, network debug UI (DEBUG), UIKit extensions |
| **LumiKitLottie** | LumiKitUI + Lottie | Lottie-powered pull-to-refresh control |

**89 source files** across 4 targets, with **566 tests** across 4 test targets:
- **LumiKitCoreTests**: 76 tests (11 suites)
- **LumiKitNetworkTests**: 8 tests (1 suite)
- **LumiKitUITests**: 475 tests (81 suites)
- **LumiKitLottieTests**: 7 tests (1 suite)

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
        "LumiKitCore",    // Foundation utilities only
        "LumiKitNetwork", // Optional: Network debugging (DEBUG only)
        "LumiKitUI",      // Full design system + components (includes Network)
        "LumiKitLottie",  // Optional: Lottie pull-to-refresh
    ]
)
```

**Note**: `LumiKitUI` automatically includes `LumiKitNetwork`, so you only need to import `LumiKitNetwork` explicitly if using it without UI components.

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

The example includes 18 interactive pages: Typography, Colors, Cards, Badges, Chips, Empty State, Buttons, Toast, Controls, Gradient, Loading State, Banner, Action Sheet, QR Code, Photo Browser, Photo Crop, Tip View, and Floating Button.

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
│   ├── LumiKitNetwork/        # [DEBUG only, isolated concurrency workarounds]
│   │   ├── LMKNetworkLogger.swift            # URLProtocol-based interception
│   │   ├── LMKNetworkRequestStore.swift       # Thread-safe ring buffer
│   │   ├── LMKNetworkRequestRecord.swift      # Request/response data
│   │   └── URLSessionConfiguration+LMKDebug.swift  # .withNetworkLogging()
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
│   │   │   ├── LMKSearchBar, LMKSkeletonCell, LMKToastView, LMKTipView,
│   │   │   ├── LMKCardPageController, LMKCardPageLayout,
│   │   │   └── LMKCardPanelController, LMKCardPanelLayout
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
│   │   ├── Debug/             # [DEBUG only]
│   │   │   └── Network/       # LMKNetworkHistoryViewController, LMKNetworkDetailViewController
│   │   ├── Extensions/        # UIKit extensions (lmk_ prefix)
│   │   ├── Haptics/           # LMKHapticFeedbackHelper
│   │   ├── Photo/             # LMKPhotoBrowserViewController, LMKPhotoBrowserCell,
│   │   │                      # LMKPhotoCropViewController, LMKPhotoEXIFService,
│   │   │                      # LMKPhotoBrowserConfig
│   │   ├── QRCode/            # LMKQRCodeGenerator
│   │   ├── Share/             # LMKShareService, LMKSharePreviewViewController
│   │   └── Utilities/         # LMKDeviceHelper, LMKKeyboardObserver,
│   │                          # LMKSceneUtil, LMKImageUtil, LMKOverscrollFooterHelper
│   └── LumiKitLottie/         # LMKLottieRefreshControl
├── Tests/
│   ├── LumiKitCoreTests/      # 76 tests, 11 suites
│   │   ├── Concurrency/       # LMKConcurrencyHelpers
│   │   ├── Data/              # String+LMK, Collection+LMK, NSAttributedString+LMK, FormatHelper
│   │   ├── Date/              # DateHelper, DateFormatterHelper
│   │   ├── File/              # FileUtil
│   │   ├── Log/               # LMKLogStore (ring buffer, thread safety),
│   │   │                      # LMKLogger (log store integration)
│   │   └── Validation/        # URLValidator
│   ├── LumiKitNetworkTests/   # 8 tests, 1 suite
│   │   └── LMKNetworkRequestStoreTests.swift  # FIFO, thread safety
│   ├── LumiKitUITests/        # 475 tests, 81 suites
│   │   ├── Alerts/            # AlertPresenter, ErrorHandler
│   │   ├── Animation/         # AnimationHelper
│   │   ├── Components/
│   │   │   ├── BottomSheet/   # BottomSheetController, ActionSheet, BottomSheetLayout
│   │   │   ├── Pickers/       # DatePickerHelper
│   │   │   ├── Badge, Banner, Card, Chip, Divider, EmptyState,
│   │   │   ├── Gradient, LoadingState, SearchBar, Skeleton, Toast,
│   │   │   └── FloatingButton, TipView, CardPage, CardPanel
│   │   ├── Controls/          # Button, SegmentedControl, TextField, TextView, ToggleButton
│   │   ├── DesignSystem/
│   │   │   ├── Tokens/        # Color, Spacing, CornerRadius, Alpha, Typography, Layout, Shadow
│   │   │   ├── Themes/        # AnimationTheme, BadgeTheme, SendableCompliance
│   │   │   ├── Factories/     # ButtonFactory, CardFactory, LabelFactory
│   │   │   └── ThemeManager, ComponentToken integration
│   │   ├── Extensions/        # UIColor, UIImage, UIStackView,
│   │   │                      # UIView (shadow/border/fade/layout)
│   │   ├── Photo/             # CropAspectRatio, PhotoEXIF
│   │   ├── QRCode/            # QRCodeGenerator
│   │   ├── Share/             # SharePreview, ShareService
│   │   └── Utilities/         # DeviceHelper, ImageUtil, KeyboardObserver
│   └── LumiKitLottieTests/    # 7 tests, 1 suite
│       └── LMKLottieRefreshControlTests.swift
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
| `LMKTipView` | Onboarding tip with centered or pointed (arrow) styles — tap to dismiss |
| `LMKFloatingButton` | Draggable floating action button with edge snapping and optional badge |
| `LMKCardPageController` | Base class for card-embedded navigation pages with header, title, and multi-page slide navigation |
| `LMKCardPanelController` | Centered floating card panel in its own overlay window, with shadow and slide animation |
| `LMKCardPageLayout` | Shared layout constants for card page controllers (header height, symbol sizes) |
| `LMKCardPanelLayout` | Shared layout constants for card panel controllers (max width, insets, height ratio) |

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
| `UIView+LMKLayout` | `lmk_safeAreaSnp`, `lmk_setEdgesEqualToSuperview()`, `lmk_centerInSuperview()`, `lmk_setAutoLayoutSize(width:height:)` |
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
| `LMKOverscrollFooterHelper` | Positions a footer view below scroll content, revealed only on overscroll |

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

## Debug Tools (DEBUG builds only)

Network debugging infrastructure for capturing and inspecting HTTP/HTTPS requests during development. **Zero footprint in release builds** — all code is wrapped in `#if DEBUG`.

**Isolated in `LumiKitNetwork` target** to keep Swift 6 concurrency workarounds separate from core functionality.

### Network Debugging

| Component | Target | Purpose |
|-----------|--------|---------|
| `LMKNetworkLogger` | LumiKitNetwork | URLProtocol-based request/response interception with LMKLogger-style API |
| `LMKNetworkRequestStore` | LumiKitNetwork | Thread-safe ring buffer for captured requests (FIFO eviction with `OSAllocatedUnfairLock`) |
| `LMKNetworkRequestRecord` | LumiKitNetwork | Sendable struct with HTTP request/response details and formatted display properties |
| `LMKNetworkHistoryViewController` | LumiKitUI | List view for captured requests with auto-refresh and newest-first ordering |
| `LMKNetworkDetailViewController` | LumiKitUI | Detail view with formatted headers and bodies (50k char truncation for large payloads) |

### Usage

```swift
// 1. Configure at app launch (DEBUG builds only)
#if DEBUG
LMKNetworkLogger.configure(maxRecords: 100)
LMKNetworkLogger.enable()
#endif

// 2. Inject into custom URLSession configurations
#if DEBUG
let config = URLSessionConfiguration.default.withNetworkLogging()
#endif

// 3. Present network history UI from debug menu
let vc = LMKNetworkHistoryViewController()
navigationController.pushViewController(vc, animated: true)
```

### Swift 6 Concurrency Support

Network debugging works correctly in Swift 6 strict concurrency mode, including Swift Package Manager builds. The implementation uses specific patterns to avoid deadlocks and timeouts.

**Implementation details:**
- **Isolated** in separate `LumiKitNetwork` target to keep debug tooling separate from `LumiKitCore`
- **Enabled** automatically in DEBUG builds via `LMK_ENABLE_NETWORK_LOGGING` flag (defined in Package.swift)
- Uses `@preconcurrency @objc` and `@unchecked Sendable` on URLProtocol subclass
- Conforms to `URLSessionDataDelegate` (not base `URLSessionDelegate`) to ensure delegate callbacks are invoked
- Uses serial `OperationQueue` for delegate callbacks (not `nil`) to prevent Swift 6 concurrency deadlocks
- Internal URLSession uses `ephemeral` configuration with `protocolClasses = []` to prevent re-interception loops

**Apps using network debugging:**
- Import `LumiKitNetwork` explicitly, or just import `LumiKitUI` (which includes it)
- No additional configuration required - network logging works in both Xcode projects and Swift Package Manager builds

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

### Infrastructure
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
