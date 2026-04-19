# LumiKit — Claude Code Guide

> Shared Swift Package providing design tokens, UI components, and utilities for Lumi apps.
> **Inherits general Swift/UIKit standards from [workspace CLAUDE.md](../../.claude/CLAUDE.md).** This file contains LumiKit-specific rules only.

---

## Package Overview

| Target | Dependencies | Purpose |
|--------|-------------|---------|
| **LumiKitCore** | Foundation only | Logger (+ LogStore ring buffer), DateHelper, URLValidator, ConcurrencyHelpers, FormatHelper, FileHelper, String/Collection/NSAttributedString extensions |
| **LumiKitNetwork** | LumiKitCore | Network debugging with URLProtocol interception (DEBUG only, `LMK_ENABLE_NETWORK_LOGGING` flag) |
| **LumiKitUI** | LumiKitCore + LumiKitNetwork + SnapKit | Design system tokens, theme, animation, haptics, alerts, components, controls, utilities, photo browser/crop/EXIF, share, QR code, network debug UI (DEBUG), extensions |
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
│   │   ├── Data/            # LMKFormatHelper, String+LMK, Collection+LMK, NSAttributedString+LMK
│   │   ├── Date/            # LMKDateHelper, LMKDateFormatterHelper
│   │   ├── File/            # LMKFileUtil
│   │   ├── Log/             # LMKLogger, LMKLogStore (ring buffer), LMKLogLevel, LMKLogEntry
│   │   └── Validation/      # LMKURLValidator
│   ├── LumiKitNetwork/        # [DEBUG only, LMK_ENABLE_NETWORK_LOGGING flag]
│   │   ├── LMKNetworkLogger.swift            # URLProtocol-based interception
│   │   ├── LMKNetworkRequestStore.swift       # Thread-safe FIFO store (OSAllocatedUnfairLock)
│   │   ├── LMKNetworkRequestRecord.swift      # Request/response data model
│   │   └── URLSessionConfiguration+LMKDebug.swift  # .enableNetworkLogging()
│   ├── LumiKitUI/
│   │   ├── Alerts/          # LMKAlertPresenter, LMKErrorHandler, LMKCountdownConfirmation
│   │   ├── Animation/       # LMKAnimationHelper
│   │   ├── Components/
│   │   │   ├── BottomSheet/  # LMKBottomSheetController (base), LMKActionSheet,
│   │   │   │                 # LMKEnumSelectionBottomSheet, LMKBottomSheetLayout
│   │   │   ├── Pickers/      # LMKDatePickerHelper
│   │   │   └── (root)        # Badge, Banner, Card, Chip, Divider, EmptyState,
│   │   │                     # FilterChipBar, FloatingButton, Gradient, LoadingState,
│   │   │                     # NavigationBar, NavigationController,
│   │   │                     # PageIndicator, Progress,
│   │   │                     # SearchBar, Skeleton, Toast, TipView,
│   │   │                     # CardPageController, CardPageLayout,
│   │   │                     # CardPanelController, CardPanelLayout,
│   │   │                     # NavigationDirection, OverscrollFooterHelper,
│   │   │                     # ScrollStackViewController
│   │   ├── Controls/        # LMKButton, LMKSegmentedControl, LMKSwitch,
│   │   │                    # LMKToggleButton, LMKTextField, LMKTextView
│   │   ├── DesignSystem/
│   │   │   ├── Tokens/       # LMKColor, LMKSpacing, LMKCornerRadius, LMKAlpha,
│   │   │   │                 # LMKLayout, LMKShadow, LMKTypography, LMKBadge
│   │   │   ├── Themes/       # LMKSpacingTheme, LMKCornerRadiusTheme, LMKAlphaTheme,
│   │   │   │                 # LMKLayoutTheme, LMKShadowTheme, LMKTypographyTheme,
│   │   │   │                 # LMKBadgeTheme, LMKAnimationTheme
│   │   │   ├── Factories/    # LMKButtonFactory, LMKCardFactory, LMKLabelFactory
│   │   │   └── LMKTheme.swift  # LMKTheme protocol + LMKThemeManager + LMKDefaultTheme
│   │   ├── Debug/            # [DEBUG only]
│   │   │   └── Network/     # LMKNetworkHistoryViewController, LMKNetworkDetailViewController
│   │   ├── Extensions/      # UIKit extensions (lmk_ prefix): UIColor, UIImage, UIView,
│   │   │                    # UIStackView, UITextField, UIButton, UITableViewCell, etc.
│   │   ├── Haptics/         # LMKHapticFeedbackHelper
│   │   ├── Photo/           # LMKPhotoBrowserViewController, LMKPhotoBrowserCell,
│   │   │                    # LMKPhotoCropViewController, LMKPhotoGridViewController,
│   │   │                    # LMKPhotoGridCell, LMKPhotoEXIFService, LMKPhotoBrowserConfig
│   │   ├── QRCode/          # LMKQRCodeGenerator
│   │   ├── Share/           # LMKShareService, LMKSharePreviewViewController
│   │   └── Utilities/       # LMKDeviceHelper, LMKKeyboardObserver, LMKSceneUtil,
│   │                        # LMKImageUtil, LMKMarkdownRenderer
│   └── LumiKitLottie/       # LMKLottieRefreshControl
├── Tests/
│   ├── LumiKitCoreTests/    # 76 tests, 11 suites
│   │   ├── Concurrency/     # LMKConcurrencyHelpersTests
│   │   ├── Data/            # String+LMK, Collection+LMK, NSAttributedString+LMK, FormatHelper
│   │   ├── Date/            # DateHelper, DateFormatterHelper
│   │   ├── File/            # FileUtil
│   │   ├── Log/             # LMKLogStoreTests (ring buffer, thread safety), LMKLoggerTests (log store integration)
│   │   └── Validation/      # URLValidator
│   ├── LumiKitNetworkTests/  # 65 tests, 4 suites
│   │   ├── LMKNetworkRequestStoreTests.swift         # FIFO, thread safety
│   │   ├── LMKNetworkRequestRecordTests.swift        # Computed properties, display formatting
│   │   ├── LMKNetworkLoggerTests.swift               # Configuration, state transitions
│   │   └── URLSessionConfigurationLMKDebugTests.swift # enableNetworkLogging
│   ├── LumiKitLottieTests/  # 7 tests, 1 suite
│   │   └── LMKLottieRefreshControlTests.swift
│   └── LumiKitUITests/      # 670 tests, 82 suites
│       ├── Alerts/          # AlertPresenter, ErrorHandler
│       ├── Animation/       # AnimationHelper
│       ├── Components/
│       │   ├── BottomSheet/  # BottomSheetController, ActionSheet, BottomSheetLayout,
│       │   │                 # EnumSelectionBottomSheet
│       │   ├── Pickers/      # DatePickerHelper
│       │   └── (root)        # Badge, Banner, Card, Chip, Divider, EmptyState,
│       │                     # FilterChipBar, FloatingButton, Gradient, LoadingState, Progress,
│       │                     # SearchBar, Skeleton, Toast, TipView, CardPage,
│       │                     # CardPanel, ScrollStackViewController
│       ├── Controls/        # Button, SegmentedControl, TextField, TextView, ToggleButton
│       ├── DesignSystem/
│       │   ├── Tokens/       # Color, Spacing, CornerRadius, Alpha, Typography, Layout, Shadow
│       │   ├── Themes/       # AnimationTheme, BadgeTheme, SendableCompliance
│       │   ├── Factories/    # ButtonFactory, CardFactory, LabelFactory
│       │   └── (root)        # ThemeManager, ComponentToken integration
│       ├── Extensions/      # UIColor, UIImage, UIStackView,
│       │                    # UIView (shadow/border/fade/layout),
│       │                    # UIViewController (TopViewController)
│       ├── Photo/           # CropAspectRatio, PhotoEXIF
│       ├── QRCode/          # QRCodeGenerator
│       ├── Share/           # SharePreview, ShareService
│       └── Utilities/       # DeviceHelper, ImageUtil, KeyboardObserver,
│                            # KeyboardInsetHelper, MarkdownRenderer
```

---

## Naming Conventions

- **Public types**: `LMK` prefix (e.g. `LMKColor`, `LMKSpacing`, `LMKAnimationHelper`)
- **Extension methods**: `lmk_` prefix (e.g. `view.lmk_addSubviews(...)`)
- **Theme configs**: `LMK*Theme` structs (e.g. `LMKTypographyTheme`, `LMKSpacingTheme`)
- **Configurable strings**: Module-level `nonisolated(unsafe)` variable + `Sendable` struct
- **Protocols for data/delegates**: `LMKPhotoBrowserDataSource`, `LMKPhotoCropDelegate`, `LMKSharePreviewDelegate`

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
| Animation | `LMKAnimationHelper` | `LMKAnimationTheme` | `.Duration.*`, `.Spring.damping`, `.shouldAnimate`, `.shimmer` |
| Badge | `LMKBadgeView` | `LMKBadgeTheme` | `minWidth`, `height`, `horizontalPadding`, `borderWidth` |

### Design System Files

```
DesignSystem/
├── LMKTheme.swift              # LMKTheme protocol + LMKThemeManager + LMKDefaultTheme
├── Tokens/
│   ├── LMKColor.swift          # Color proxy -> LMKThemeManager.shared.current
│   ├── LMKTypography.swift     # Font proxy -> LMKThemeManager.shared.typography
│   ├── LMKSpacing.swift        # Spacing proxy
│   ├── LMKCornerRadius.swift   # Corner radius proxy
│   ├── LMKAlpha.swift          # Alpha proxy
│   ├── LMKLayout.swift         # Layout dimensions proxy
│   ├── LMKShadow.swift         # Shadow proxy
│   └── LMKBadge.swift          # Badge proxy -> LMKThemeManager.shared.badge
├── Themes/
│   ├── LMKTypographyTheme.swift    # fontFamily, sizes, weights, line heights
│   ├── LMKSpacingTheme.swift       # 4pt grid values
│   ├── LMKCornerRadiusTheme.swift  # Corner radius config
│   ├── LMKAlphaTheme.swift         # Alpha/opacity config
│   ├── LMKLayoutTheme.swift        # Layout dimensions config
│   ├── LMKShadowTheme.swift        # Shadow config
│   └── LMKBadgeTheme.swift         # Badge sizing config
└── Factories/
    ├── LMKButtonFactory.swift      # Role-based button factory (LMKButtonRole + filled/outlined/ghost/iconOnly)
    ├── LMKCardFactory.swift        # Factory methods for card views
    └── LMKLabelFactory.swift       # Factory methods for styled labels
```

### Pattern: Token Enum -> Config Struct -> ThemeManager

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
| `LMKBottomSheetController` | `open class` | Base class for bottom sheet presentation — shared dimming, container, animation, dismiss |
| `LMKActionSheet` | `final class` | Custom bottom-sheet action sheet with design-token styling, optional custom content, `isSelected` checkmark state, and sub-page navigation |
| `LMKBadgeView` | `final class` | Notification count / status dot / custom text badge |
| `LMKBannerView` | `final class` | Persistent notification bar with optional action & dismiss |
| `LMKCardView` | `final class` | Card container with shadow, corner radius, content insets |
| `LMKChipView` | `final class` | Tag/filter chip (`.filled` / `.outlined`) with optional tap handler |
| `LMKFilterChipBar` | `final class` | Horizontal scrolling single-select chip bar built on `LMKChipView`. Optional "All" chip clears the filter. `configure(allTitle:filterTitles:style:)`, `setSelectedIndex(_:)` (silent), `selectionChangedHandler: ((Int?) -> Void)` — `nil` index = "All" / no selection |
| `LMKDividerView` | `final class` | Pixel-perfect separator (horizontal / vertical) |
| `LMKEmptyStateView` | `final class` | Empty state with icon, title, message, action button |
| `LMKEnumSelectionBottomSheet` | `final class` | Generic bottom sheet for selecting from an enum's cases. `present(...)` for single-select (auto-commits on tap); `presentMultiSelect(...)` for multi-select (tap toggles, explicit Done button commits) |
| `LMKGradientView` | `final class` | CAGradientLayer-backed view with 4 direction options |
| `LMKLoadingStateView` | `final class` | Loading indicator with optional message |
| `LMKNavigationBar` | `final class` | Custom navigation bar with large title and standard inline modes. Configurable back button, left/right `LMKNavigationBarItem` arrays, separator, appearance (background, tint, title font/color). `pinToTop(of:)` for layout. `setLeftItemEnabled(at:_:)` / `setRightItemEnabled(at:_:)` toggle per-item enabled state (disabled items render at `LMKAlpha.disabled` and stop firing their action) |
| `LMKNavigationController` | `open class` | `UINavigationController` subclass that keeps the interactive edge-swipe-to-go-back gesture working when the system nav bar is hidden (as it is in apps using `LMKNavigationBar`). Installs itself as the pop-gesture delegate and enables the gesture only when the stack has 2+ VCs |
| `LMKPageIndicator` | `final class` | Custom page indicator replacing `UIPageControl`. Active dot expands into pill with spring animation. `numberOfPages`, `currentPage`, `pageChangedHandler` |
| `LMKProgressViewController` | `final class` | Blocking progress modal (`.determinate` with progress bar, `.indeterminate` spinner-only) |
| `LMKSearchBar` | `final class` | Search bar with configurable strings |
| `LMKSkeletonCell` | `final class` | Skeleton loading placeholder cell |
| `LMKToastView` | `final class` | Auto-dismissing toast notification |
| `LMKTipView` | `final class` | Onboarding tip with centered or pointed (arrow) styles |
| `LMKFloatingButton` | `final class` | Draggable floating action button with edge snapping and badge |
| `LMKCardPageController` | `open class` | Base class for card-embedded navigation pages with header, title, multi-page slide |
| `LMKCardPanelController` | `open class` | Centered floating card panel in its own overlay window with slide animation |
| `LMKCardPageLayout` | `enum` (static) | Shared layout constants for card pages (header height, symbol sizes) |
| `LMKCardPanelLayout` | `enum` (static) | Shared layout constants for card panels (max width, insets, height ratio) |
| `LMKScrollStackViewController` | `open class` | Base class for scrollable vertical stack layout — configurable spacing, insets, keyboard dismiss, safe area, bounce. Subclasses override `setupStackContent()` |
| `LMKNavigationDirection` | `enum` | Shared navigation direction (`.forward`, `.backward`, `.none`) used by CardPageController and ActionSheet |
| `LMKOverscrollFooterHelper` | `final class` | Positions footer below scroll content, revealed on overscroll |

### Controls (`Controls/`)

| Control | Type | Purpose |
|---------|------|---------|
| `LMKButton` | `open class` | UIButton subclass with 4 styles: `.filled`, `.outlined`, `.ghost` (text-only), `.iconOnly` (circular). Capsule corners, press animation, `isLoading` state. `tapHandler`/`didTapHandler` closures |
| `LMKSegmentedControl` | `open class` | Custom `UIControl` (NOT `UISegmentedControl`) with sliding pill indicator, spring animation, haptic. `init(items:)`, `selectedSegmentIndex` (`-1` = no selection, hides indicator — matches `UISegmentedControl.noSegment`), `valueChangedHandler`, `fitsSegmentsToContent` (per-segment natural width), `makeScrollableContainer()` |
| `LMKSwitch` | `final class` | Custom toggle replacing `UISwitch`. Rounded track + sliding thumb, spring animation, haptic. `isOn`, `setOn(_:animated:)`, `valueChangedHandler`. Sends `.valueChanged` |
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
| `UIView+LMKLayout` | `lmk_safeAreaSnp`, `lmk_setEdgesEqualToSuperview()`, `lmk_centerInSuperview()`, `lmk_setAutoLayoutSize(width:height:)` |
| `UIStackView+LMK` | `init(lmk_axis:...)`, `lmk_addArrangedSubviews(_:)`, `lmk_removeAllArrangedSubviews()` |

### Share (`Share/`)

| Component | Type | Purpose |
|-----------|------|---------|
| `LMKShareResult` | `enum` | Result of share operation: `.completed(ActivityType?)`, `.cancelled`, `.failed(Error)` |
| `LMKShareService` | `enum` (static) | Share sheet wrapper — `shareImage` (returns `LMKShareResult`), `shareFile` with popover support |
| `LMKSharePreviewViewController` | `final class` | Image preview sheet with share + save-to-photos. All feedback is delegate-driven via `LMKSharePreviewDelegate` (`didShareWith`, `didFailToShare`, `sharePreviewDidSave`, `didFailToSave`) |

### QR Code (`QRCode/`)

| Component | Type | Purpose |
|-----------|------|---------|
| `LMKQRCodeGenerator` | `enum` (static) | CoreImage QR code generation with configurable correction level and size |

### Photo (`Photo/`)

| Component | Type | Purpose |
|-----------|------|---------|
| `LMKPhotoBrowserViewController` | `final class` | Full-screen photo browser with zoom, swipe, delete |
| `LMKPhotoBrowserConfig` | `enum` | Shared configuration constants (e.g. `interPageSpacing`) |
| `LMKPhotoCropViewController` | `final class` | Square crop editor with pan/zoom |
| `LMKPhotoGridViewController` | `final class` | Photo grid with pinch-to-zoom columns, sort, content mode toggle, browser integration |
| `LMKPhotoEXIFService` | `nonisolated enum` (static) | EXIF date + GPS extraction from UIImage or PHPickerResult |

### Pickers (`Components/Pickers/`)

| Component | Type | Purpose |
|-----------|------|---------|
| `LMKDatePickerHelper` | `enum` (static) | Date picker presentation via `LMKActionSheet` — single date (past/future), date range with live enforcement, date with text field. Configurable strings, auto-clamping |

### Utilities (`Utilities/`)

| Utility | Purpose |
|---------|---------|
| `LMKDeviceHelper` | Device type (`.iPhone`, `.iPad`, `.macCatalyst`), screen size classification, notch detection |
| `LMKKeyboardObserver` | Keyboard show/hide observer with height + animation info |
| `LMKImageUtil` | SF Symbol creation (`makeSymbolImage` with background), `CVPixelBuffer` to JPEG conversion |
| `LMKMarkdownRenderer` | Markdown-to-attributed-string: `render()` for inline (bold/italic), `renderFull()` for long-form content (headings, lists, `\n` preserved), `makeInlineTextView` |
| `LMKSceneUtil` | Key window and connected scene retrieval |

---

## Error Handling

- **`LMKErrorHandler`** for user-facing errors — supports severity-based presentation:
  - `.info` -> info toast
  - `.warning` -> alert with OK
  - `.error` -> toast (transient) or alert with retry (recoverable)
  - `.critical` -> always alert, retry if available
- All presentation methods auto-log via `LMKLogger`
- **`LMKAlertPresenter`** for generic alerts and action sheets
- **`LMKCountdownConfirmation`** for destructive actions — confirm button disabled for a countdown period (default 3s) with live title countdown, preventing accidental taps

---

## Build & Test Commands

```bash
# Build all targets (iOS Simulator)
xcodebuild build \
  -scheme LumiKit-Package \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2' \
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
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2' \
  -skipPackagePluginValidation \
  CODE_SIGNING_ALLOWED=NO 2>&1 | tail -20

# Build single target (faster iteration)
swift build --target LumiKitCore

# Build Example app (XcodeGen project — must use -scheme, NEVER -target)
cd Example && xcodebuild build \
  -project LumiKitExample.xcodeproj \
  -scheme LumiKitExample \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2' \
  -skipPackagePluginValidation \
  CODE_SIGNING_ALLOWED=NO 2>&1 | tail -5
```

---

## Forced Dark Mode + Status Bar Pattern

View controllers that force dark mode (e.g., photo browser, crop editor) must follow this 3-step pattern:

```swift
public final class LMKExampleViewController: UIViewController {
    // 1. Explicitly return .lightContent (don't rely on system inference)
    override public var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    public init() {
        super.init(nibName: nil, bundle: nil)
        // 2. Tell UIKit this presented VC controls the status bar
        modalPresentationCapturesStatusBarAppearance = true
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        // 3. Force dark appearance on this VC's view hierarchy
        overrideUserInterfaceStyle = .dark
    }
}
```

**Why all three?**
- `overrideUserInterfaceStyle = .dark` — forces dark appearance for colors, materials, and vibrancy
- `preferredStatusBarStyle = .lightContent` — explicit is safer than relying on system inference from interface style
- `modalPresentationCapturesStatusBarAppearance = true` — required for modally presented VCs to control the status bar; without this, the **presenting** VC's status bar style is used

**UINavigationController gotcha**: UIKit asks the **container** (not the child) for `preferredStatusBarStyle`. If a forced-dark VC is embedded in a navigation controller, either:
- Subclass the nav controller and override `childForStatusBarStyle` to return `topViewController`
- Or set `navigationBar.barStyle = .black` to force light status bar content

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

*Optimized for Claude Code • Last updated: 2026-04-07*
