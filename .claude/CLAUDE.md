# LumiKit — Claude Code Guide

> Shared Swift Package providing design tokens, UI components, and utilities for Lumi apps.

---

## Package Overview

| Target | Dependencies | Purpose |
|--------|-------------|---------|
| **LumiKitCore** | Foundation only | Logger, DateHelper, URLValidator, ConcurrencyHelpers, FormatHelper, FileHelper, String/Collection/NSAttributedString extensions |
| **LumiKitUI** | LumiKitCore + SnapKit | Design system tokens, theme, animation, haptics, alerts, components, controls, utilities, photo browser/crop/EXIF, share, QR code, extensions |
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
│   │   ├── Data/            # LMKFormatHelper, LMKLogger, Collection+LMK, NSAttributedString+LMK
│   │   ├── Date/            # LMKDateHelper, LMKDateFormatterHelper
│   │   ├── File/            # LMKFileUtil
│   │   └── Validation/      # LMKURLValidator, String+LMK
│   ├── LumiKitUI/
│   │   ├── Alerts/          # LMKAlertPresenter, LMKErrorHandler
│   │   ├── Animation/       # LMKAnimationHelper, LMKAnimationTheme
│   │   ├── Components/      # LMKEmptyStateView, LMKToastView, LMKSearchBar, LMKBadgeView,
│   │   │                    # LMKChipView, LMKDividerView, LMKGradientView, LMKCardView,
│   │   │                    # LMKBannerView, LMKSkeletonCell, LMKLoadingStateView, etc.
│   │   ├── Controls/        # LMKButton, LMKSegmentedControl, LMKToggleButton,
│   │   │                    # LMKTextField, LMKTextView
│   │   ├── DesignSystem/    # Token enums + Theme configs (see below)
│   │   ├── Extensions/      # UIKit extensions (lmk_ prefix): UIColor, UIImage, UIView,
│   │   │                    # UIStackView, UITextField, UIButton, UITableViewCell, etc.
│   │   ├── Haptics/         # LMKHapticFeedbackHelper
│   │   ├── Photo/           # LMKPhotoBrowserViewController, LMKPhotoCropViewController, LMKPhotoEXIFService
│   │   ├── QRCode/          # LMKQRCodeGenerator
│   │   ├── Share/           # LMKShareService, LMKSharePreviewViewController
│   │   └── Utilities/       # LMKDeviceHelper, LMKKeyboardObserver
│   └── LumiKitLottie/       # LMKLottieRefreshControl
├── Tests/
│   ├── LumiKitCoreTests/    # 56 tests, 9 suites — mirrors Sources/LumiKitCore/ subfolders
│   │   ├── Concurrency/     # LMKConcurrencyHelpersTests
│   │   ├── Data/            # Logger, String+LMK, Collection+LMK, NSAttributedString+LMK, FormatHelper
│   │   ├── Date/            # DateHelper, DateFormatterHelper
│   │   └── Validation/      # URLValidator
│   └── LumiKitUITests/      # 178 tests, 51 suites — mirrors Sources/LumiKitUI/ subfolders
│       ├── Alerts/          # AlertPresenter, ErrorHandler
│       ├── Animation/       # AnimationHelper
│       ├── Components/      # ActionSheet, Badge, Banner, Card, Chip, Divider,
│       │                    # EmptyState, Gradient, LoadingState, Skeleton, Toast
│       ├── Controls/        # SegmentedControl, TextField, TextView, ToggleButton
│       ├── DesignSystem/    # ThemeManager, Color, Spacing, CornerRadius, Alpha,
│       │                    # Typography, Layout, Shadow, AnimationTheme, BadgeTheme,
│       │                    # Sendable compliance, ComponentToken integration
│       ├── Extensions/      # UIColor, UIImage, UIStackView, UIView (shadow/border/fade)
│       ├── Photo/           # CropAspectRatio, PhotoEXIF
│       ├── QRCode/          # QRCodeGenerator
│       ├── Share/           # SharePreview, ShareService
│       └── Utilities/       # DeviceHelper, KeyboardObserver
```

---

## Naming Conventions

- **Public types**: `LMK` prefix (e.g. `LMKColor`, `LMKSpacing`, `LMKAnimationHelper`)
- **Extension methods**: `lmk_` prefix (e.g. `view.lmk_addSubviews(...)`)
- **Theme configs**: `LMK*Theme` structs (e.g. `LMKTypographyTheme`, `LMKSpacingTheme`)
- **Configurable strings**: Module-level `nonisolated(unsafe)` variable + `Sendable` struct
- **Protocols for data/delegates**: `LMKPhotoBrowserDataSource`, `LMKPhotoCropDelegate`, `LMKSharePreviewDelegate`

### Modern Swift Syntax

- **Implicit returns** — already adopted; all switch cases use implicit returns
- **`any` for existentials** — use on delegate/dataSource properties: `public weak var delegate: (any LMKPhotoCropDelegate)?`
- **`some` for opaque parameters** — already adopted: `func apply(_ theme: some LMKTheme)`
- **if-let shorthand** — use `if let x {` when rebinding the same name

---

## Swift 6.2 Concurrency Patterns

- LumiKitUI and LumiKitLottie use `defaultIsolation: MainActor` — all types are MainActor by default (no explicit `@MainActor` needed)
- Pure data types (Sendable structs, protocols) must opt out with `nonisolated`
- **Theme config structs** are `nonisolated struct: Sendable` — can be created/passed from any context
- **Token enums** (LMKColor, LMKTypography, etc.) are `@MainActor` — accessed only from main thread
- Configurable strings accessed from non-MainActor contexts **must** be module-level `nonisolated(unsafe)`
- `LMKConcurrencyHelpers.encode/decode` — off-main-thread Codable operations

---

## Design System — Fully Configurable Tokens

**All tokens are customizable** via `LMKThemeManager`. Each category has a configuration struct with defaults matching the built-in values. Token enums proxy to the active configuration.

### Configuration at App Launch

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

### Token Categories

| Category | Proxy Enum | Config Struct | Key Properties |
|----------|-----------|---------------|----------------|
| Colors | `LMKColor` | `LMKTheme` (protocol) | `.primary`, `.backgroundPrimary`, `.textPrimary` |
| Typography | `LMKTypography` | `LMKTypographyTheme` | `fontFamily`, `h1Size`, `bodySize`, line heights, letter spacing |
| Spacing | `LMKSpacing` | `LMKSpacingTheme` | `.xs` (4pt), `.small` (8pt), `.medium` (12pt), `.large` (16pt) |
| Corner Radius | `LMKCornerRadius` | `LMKCornerRadiusTheme` | `.small` (8), `.medium` (12), `.large` (16) |
| Alpha | `LMKAlpha` | `LMKAlphaTheme` | `.overlay`, `.disabled`, `.overlayStrong` |
| Layout | `LMKLayout` | `LMKLayoutTheme` | `.minimumTouchTarget` (44), `.iconMedium` (24), `.searchBarHeight` (36) |
| Shadow | `LMKShadow` | `LMKShadowTheme` | `cellCard()`, `card()`, `button()`, `small()` |
| Animation | `LMKAnimationHelper` | `LMKAnimationTheme` | `.Duration.*`, `.Spring.damping`, `.shouldAnimate` |
| Badge | `LMKBadgeView` | `LMKBadgeTheme` | `minWidth`, `height`, `horizontalPadding`, `borderWidth` |

### Design System Files

```
DesignSystem/
├── LMKTheme.swift              # LMKTheme protocol + LMKThemeManager (holds all configs)
├── LMKColor.swift              # Color proxy → LMKThemeManager.shared.current
├── LMKTypography.swift         # Font proxy → LMKThemeManager.shared.typography
├── LMKTypographyTheme.swift    # Configuration struct (fontFamily, sizes, weights)
├── LMKSpacing.swift            # Spacing proxy → LMKThemeManager.shared.spacing
├── LMKSpacingTheme.swift       # Configuration struct
├── LMKCornerRadius.swift       # Corner radius proxy
├── LMKCornerRadiusTheme.swift  # Configuration struct
├── LMKAlpha.swift              # Alpha proxy
├── LMKAlphaTheme.swift         # Configuration struct
├── LMKLayout.swift             # Layout dimensions proxy
├── LMKLayoutTheme.swift        # Configuration struct
├── LMKShadow.swift             # Shadow proxy
├── LMKShadowTheme.swift        # Configuration struct
├── LMKBadgeTheme.swift         # Badge sizing configuration struct
├── LMKButtonFactory.swift      # Factory methods for styled buttons
├── LMKCardFactory.swift        # Factory methods for card views
└── LMKLabelFactory.swift       # Factory methods for styled labels
```

### Pattern: Token Enum → Config Struct → ThemeManager

```swift
// 1. Config struct with defaults (nonisolated, Sendable)
public nonisolated struct LMKSpacingTheme: Sendable {
    public var large: CGFloat
    public init(large: CGFloat = 16, ...) { ... }
}

// 2. Token enum proxies to config (inherits @MainActor)
public enum LMKSpacing {
    private static var config: LMKSpacingTheme { LMKThemeManager.shared.spacing }
    public static var large: CGFloat { config.large }
}

// 3. ThemeManager holds the active config
LMKThemeManager.shared.apply(spacing: .init(large: 20))
```

---

## Components Reference

### Visual Components (`Components/`)

| Component | Type | Purpose |
|-----------|------|---------|
| `LMKActionSheet` | `final class` | Custom bottom-sheet action sheet with design-token styling and optional custom content |
| `LMKBadgeView` | `final class` | Notification count / status dot / custom text badge |
| `LMKBannerView` | `final class` | Persistent notification bar with optional action & dismiss |
| `LMKCardView` | `final class` | Card container with shadow, corner radius, content insets |
| `LMKChipView` | `final class` | Tag/filter chip (`.filled` / `.outlined`) with optional tap handler |
| `LMKDividerView` | `final class` | Pixel-perfect separator (horizontal / vertical) |
| `LMKEmptyStateView` | `final class` | Empty state with icon, title, message, action button |
| `LMKEnumSelectionBottomSheet` | `final class` | Generic bottom sheet for selecting from an enum's cases |
| `LMKGradientView` | `final class` | CAGradientLayer-backed view with 4 direction options |
| `LMKLoadingStateView` | `final class` | Loading indicator with optional message |
| `LMKProgressViewController` | `final class` | Progress indicator view controller |
| `LMKSearchBar` | `final class` | Search bar with configurable strings |
| `LMKSkeletonCell` | `final class` | Skeleton loading placeholder cell |
| `LMKToastView` | `final class` | Auto-dismissing toast notification |

### Controls (`Controls/`)

| Control | Type | Purpose |
|---------|------|---------|
| `LMKButton` | `open class` | Configurable button with tap handler, styles |
| `LMKSegmentedControl` | `open class` | Custom segmented control |
| `LMKTextField` | `open class` | Text field with validation states, helper text, leading icon |
| `LMKTextView` | `open class` | Multi-line text input with placeholder, character limit |
| `LMKToggleButton` | `open class` | Toggle button with on/off states |

### UIKit Extensions (`Extensions/`)

| Extension | Key Methods |
|-----------|-------------|
| `UIColor+LMK` | `init(lmk_hex:)`, `lmk_hexString`, `lmk_isLight`, `lmk_adjustedBrightness(by:)`, `lmk_contrastingTextColor` |
| `UIImage+LMK` | `lmk_resized(maxDimension:)`, `lmk_resized(to:)`, `lmk_solidColor(_:size:)`, `lmk_rounded(cornerRadius:)` |
| `UIView+LMKShadow` | `lmk_applyShadow(_:)`, `lmk_removeShadow()` |
| `UIView+LMKBorder` | `lmk_applyBorder(...)`, `lmk_removeBorder()`, `lmk_applyCornerRadius(_:)`, `lmk_makeCircular()` |
| `UIView+LMKFade` | `lmk_fadeIn(...)`, `lmk_fadeOut(...)` |
| `UIView+LMKLayout` | `lmk_addSubviews(...)`, `lmk_pinToEdges(...)` |
| `UIStackView+LMK` | `init(lmk_axis:...)`, `lmk_addArrangedSubviews(_:)`, `lmk_removeAllArrangedSubviews()` |

### Share (`Share/`)

| Component | Type | Purpose |
|-----------|------|---------|
| `LMKShareService` | `enum` (static) | Share sheet wrapper — `shareImage`, `shareFile` with popover support |
| `LMKSharePreviewViewController` | `final class` | Image preview sheet with share + save-to-photos, configurable strings, delegate |

### QR Code (`QRCode/`)

| Component | Type | Purpose |
|-----------|------|---------|
| `LMKQRCodeGenerator` | `enum` (static) | CoreImage QR code generation with configurable correction level and size |

### Photo (`Photo/`)

| Component | Type | Purpose |
|-----------|------|---------|
| `LMKPhotoBrowserViewController` | `final class` | Full-screen photo browser with zoom, swipe, delete |
| `LMKPhotoCropViewController` | `final class` | Square crop editor with pan/zoom |
| `LMKPhotoEXIFService` | `nonisolated enum` (static) | EXIF date + GPS extraction from UIImage or PHPickerResult |

### Utilities (`Utilities/`)

| Utility | Purpose |
|---------|---------|
| `LMKDeviceHelper` | Device type (`.iPhone`, `.iPad`, `.macCatalyst`), screen size classification, notch detection |
| `LMKKeyboardObserver` | Keyboard show/hide observer with height + animation info |

---

## Error Handling

- **`LMKErrorHandler`** for user-facing errors — supports severity-based presentation:
  - `.info` → info toast
  - `.warning` → alert with OK
  - `.error` → toast (transient) or alert with retry (recoverable)
  - `.critical` → always alert, retry if available
- All presentation methods auto-log via `LMKLogger`
- **`LMKAlertPresenter`** for generic alerts and action sheets

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

1. **New design token**: Add to appropriate `LMK*Theme` config struct + proxy in the token enum
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

*Optimized for Claude Code • Last updated: 2026-02-16*
