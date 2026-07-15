# LumiKit — Claude Code Guide

> Shared Swift Package providing design tokens, UI components, and utilities for Lumi apps.
> Swift 6.2, UIKit, SnapKit, iOS 18+ / Mac Catalyst 18+ / macOS 15+.

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
│   │   │   ├── Pickers/      # LMKDatePickerHelper (+ calendar range selection view)
│   │   │   └── (root)        # Badge, Banner, Card, CheckboxCell, Chip, Divider, EmptyState,
│   │   │                     # FilterChipBar, FloatingButton, Gradient, LoadingState,
│   │   │                     # NavigationBar, NavigationController,
│   │   │                     # PageIndicator, Progress,
│   │   │                     # SearchBar, Skeleton, Toast, TipView,
│   │   │                     # CardPageController, CardPageLayout,
│   │   │                     # CardPanelController, CardPanelLayout,
│   │   │                     # NavigationDirection, OverscrollFooterHelper,
│   │   │                     # ScrollStackViewController, SegmentedPageController
│   │   ├── Controls/        # LMKButton, LMKSegmentedControl, LMKSlider, LMKSwitch,
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
│   │   │                    # LMKPhotoGridCell, LMKPhotoEXIFService, LMKPhotoBrowserConfig,
│   │   │                    # LMKPhotoPickCropCoordinator, LMKSinglePhotoViewer
│   │   ├── QRCode/          # LMKQRCodeGenerator
│   │   ├── Share/           # LMKShareService, LMKSharePreviewViewController
│   │   └── Utilities/       # LMKDeviceHelper, LMKKeyboardObserver, LMKSceneUtil,
│   │                        # LMKImageUtil, LMKDominantColorExtractor, LMKMarkdownRenderer
│   └── LumiKitLottie/       # LMKLottieRefreshControl
├── Tests/
│   ├── LumiKitCoreTests/    # 76 tests, 12 suites
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
│   └── LumiKitUITests/      # 836 tests, 122 suites
│       ├── Alerts/          # AlertPresenter, ErrorHandler
│       ├── Animation/       # AnimationHelper
│       ├── Components/
│       │   ├── BottomSheet/  # BottomSheetController, ActionSheet, BottomSheetLayout,
│       │   │                 # EnumSelectionBottomSheet
│       │   ├── Pickers/      # DatePickerHelper
│       │   └── (root)        # Badge, Banner, Card, CheckboxCell, Chip, Divider, EmptyState,
│       │                     # FilterChipBar, FloatingButton, Gradient, LoadingState, Progress,
│       │                     # SearchBar, Skeleton, Toast, TipView, CardPage,
│       │                     # CardPanel, ScrollStackViewController
│       ├── Controls/        # Button, SegmentedControl, Slider, TextField, TextView, ToggleButton
│       ├── DesignSystem/
│       │   ├── Tokens/       # Color, Spacing, CornerRadius, Alpha, Typography, Layout, Shadow
│       │   ├── Themes/       # AnimationTheme, BadgeTheme, SendableCompliance
│       │   ├── Factories/    # ButtonFactory, CardFactory, LabelFactory
│       │   └── (root)        # ThemeManager, ComponentToken integration
│       ├── Extensions/      # UIColor, UIImage, UIStackView,
│       │                    # UIView (shadow/border/fade/layout),
│       │                    # UIViewController (TopViewController, KeyboardDismiss),
│       │                    # UITableViewCell (IconListRow), UITextField (KeyboardDismiss)
│       ├── Photo/           # CropAspectRatio, PhotoEXIF,
│       │                    # PhotoPickCropCoordinator, SinglePhotoViewer
│       ├── QRCode/          # QRCodeGenerator
│       ├── Share/           # SharePreview, ShareService
│       └── Utilities/       # DeviceHelper, ImageUtil, DominantColorExtractor,
│                            # KeyboardObserver, KeyboardInsetHelper, MarkdownRenderer
```

---

## Naming Conventions

- **Public types**: `LMK` prefix (e.g. `LMKColor`, `LMKSpacing`, `LMKAnimationHelper`)
- **Extension methods**: `lmk_` prefix (e.g. `view.lmk_addSubviews(...)`)
- **Theme configs**: `LMK*Theme` structs (e.g. `LMKTypographyTheme`, `LMKSpacingTheme`)
- **Configurable strings**: Module-level `nonisolated(unsafe)` variable + `Sendable` struct
- **Protocols for data/delegates**: `LMKPhotoBrowserDataSource`, `LMKPhotoGridDataSource`, `LMKPhotoCropDelegate`, `LMKSharePreviewDelegate`

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
| `LMKNavigationBar` | `final class` | Custom navigation bar with large title and standard inline modes. Configurable back button, left/right `LMKNavigationBarItem` arrays, separator, appearance (background, tint, title font/color). `pinToTop(of:)` for layout. `setLeftItemEnabled(at:_:)` / `setRightItemEnabled(at:_:)` toggle per-item enabled state (disabled items render at `LMKAlpha.disabled` and stop firing their action). `setRightAccessoryView(_:)` parks a non-tappable view (sync indicator, status icon) immediately to the left of the right items — lives outside the items stack, so `setRightItems(_:)` doesn't disturb it. `setLargeTitleAccessoryView(_:)` hangs a view off the trailing edge of the large title text (iOS Mail / Notes pattern) — the title's content-hugging priority is `.required`, so the accessory tracks the actual text width |
| `LMKNavigationController` | `open class` | `UINavigationController` subclass that keeps the interactive edge-swipe-to-go-back gesture working when the system nav bar is hidden (as it is in apps using `LMKNavigationBar`). Installs itself as the pop-gesture delegate and enables the gesture only when the stack has 2+ VCs |
| `LMKPageIndicator` | `final class` | Custom page indicator replacing `UIPageControl`. Active dot expands into pill with spring animation. `numberOfPages`, `currentPage`, `pageChangedHandler`. Display-only while `pageChangedHandler` is nil (taps / VoiceOver adjustments are ignored, so the highlight can't desync from a controller-driven host) |
| `LMKProgressViewController` | `final class` | Blocking progress modal (`.determinate` with progress bar, `.indeterminate` spinner-only) |
| `LMKSearchBar` | `final class` | Search bar with configurable strings |
| `LMKSkeletonCell` | `final class` | Skeleton loading placeholder cell |
| `LMKCheckboxCell` | `final class` | Check-off row for to-dos / checklists: checkbox + strike-through title. `configure(title:isDone:)`, `onToggle` callback. Checkbox hit area expands to `LMKLayout.minimumTouchTarget`; done state exposed via `accessibilityValue` + `.selected` trait; hosts also toggle from `didSelectRowAt` so the whole row is a target. Checkbox image is set directly, never via cross-dissolve (reuse flashes a checkmark on unrelated rows otherwise) |
| `LMKToastView` | `final class` | Auto-dismissing toast notification |
| `LMKTipView` | `final class` | Onboarding tip with centered or pointed (arrow) styles |
| `LMKFloatingButton` | `final class` | Draggable floating action button with edge snapping and badge |
| `LMKCardPageController` | `open class` | Base class for card-embedded navigation pages with header, title, multi-page slide |
| `LMKCardPanelController` | `open class` | Centered floating card panel in its own overlay window with slide animation |
| `LMKCardPageLayout` | `enum` (static) | Shared layout constants for card pages (header height, symbol sizes) |
| `LMKCardPanelLayout` | `enum` (static) | Shared layout constants for card panels (max width, insets, height ratio) |
| `LMKScrollStackViewController` | `open class` | Base class for scrollable vertical stack layout — configurable spacing, insets, keyboard dismiss, safe area, bounce. Subclasses override `setupStackContent()` |
| `LMKSegmentedPageController` | `open class` | Base class for a segmented tab container that pages between child VCs with an interactive finger-tracking pan. Subclasses override `makePages()`, `usesFullWidthSwipe(forPageAt:)` (full-width vs edge-only pan, for pages that own interior horizontal drags such as a map or month grid), `didChangePage(to:)`. Top `LMKSegmentedControl` installed via overridable `installSegmentedControl()` (default: nav title view); `setPage(_:animated:)` slides for taps / deep links. `edgePanBandWidth` / `commitVelocityThreshold` are tunable open vars |
| `LMKNavigationDirection` | `enum` | Shared navigation direction (`.forward`, `.backward`, `.none`) used by CardPageController and ActionSheet |
| `LMKOverscrollFooterHelper` | `final class` | Positions footer below scroll content, revealed on overscroll |

### Controls (`Controls/`)

| Control | Type | Purpose |
|---------|------|---------|
| `LMKButton` | `open class` | UIButton subclass with 4 styles: `.filled`, `.outlined`, `.ghost` (text-only), `.iconOnly` (circular). Capsule corners, press animation, `isLoading` state. `tapHandler`/`didTapHandler` closures |
| `LMKSegmentedControl` | `open class` | Custom `UIControl` (NOT `UISegmentedControl`) with sliding pill indicator, spring animation, haptic. `init(items:)`, `selectedSegmentIndex` (`-1` = no selection, hides indicator — matches `UISegmentedControl.noSegment`), `valueChangedHandler`, `fitsSegmentsToContent` (per-segment natural width), `makeScrollableContainer()`. `fitsSegmentsToContent` and `makeScrollableContainer()` compose — combined mode uses fit-mode exact widths (`itemPadding`) and ignores `scrollableItemPadding`. `itemSpacing` tunes the gap between segments in scrollable mode (default `LMKSpacing.medium`; non-scrollable mode always uses 0) |
| `LMKSlider` | `final class` | Tokenized continuous or step-snapped slider with optional caption (leading) + live value readout (trailing) row above the track. `value` / `setValue(_:animated:)` are silent; user drags fire `.valueChanged` + `valueChangedHandler`. `step > 0` snaps to `minimumValue + n * step` (cached snapped value bypasses `UISlider`'s float drift). `valueFormatter: ((Float) -> String)?` drives the readout; both caption and readout auto-hide when nil. Uses `LMKTypography.captionMedium` + design-token tints. Adjustable accessibility trait with live `accessibilityValue` |
| `LMKSwitch` | `final class` | Custom toggle replacing `UISwitch`. Rounded track + sliding thumb, spring animation, haptic. `isOn`, `setOn(_:animated:)`, `valueChangedHandler`. Sends `.valueChanged` |
| `LMKTextField` | `open class` | Text field with validation states, helper text, leading icon |
| `LMKTextView` | `open class` | Multi-line text input with placeholder, character limit |
| `LMKToggleButton` | `open class` | Toggle button with on/off states |

### UIKit Extensions (`Extensions/`)

| Extension | Key Methods |
|-----------|-------------|
| `UIColor+LMK` | `init(lmk_hex:)`, `lmk_dynamic(lightHex:darkHex:alpha:)`, `lmk_hexString`, `lmk_isLight`, `lmk_adjustedBrightness(by:)`, `lmk_contrastingTextColor` |
| `UIImage+LMK` | `lmk_resized(maxDimension:)`, `lmk_resized(to:)`, `lmk_solidColor(_:size:)`, `lmk_rounded(cornerRadius:)` |
| `UIView+LMKShadow` | `lmk_applyShadow(_:)`, `lmk_removeShadow()` |
| `UIView+LMKBorder` | `lmk_applyBorder(...)`, `lmk_removeBorder()`, `lmk_applyCornerRadius(_:)`, `lmk_makeCircular()` |
| `UIView+LMKFade` | `lmk_fadeIn(...)`, `lmk_fadeOut(...)` |
| `UIView+LMKLayout` | `lmk_safeAreaSnp`, `lmk_setEdgesEqualToSuperview()`, `lmk_centerInSuperview()`, `lmk_setAutoLayoutSize(width:height:)` |
| `UIStackView+LMK` | `init(lmk_axis:...)`, `lmk_addArrangedSubviews(_:)`, `lmk_removeAllArrangedSubviews()` |
| `UITableViewCell+LMKIconListRow` | `lmk_configureIconListRow(iconSystemName:title:subtitle:tint:)` — standard detail-list row: SF Symbol in a tinted circle (`LMKLayout.iconCircle`), disclosure, LumiKit highlight |
| `UITextField+LMKKeyboardDismiss` | `lmk_dismissKeyboardOnReturn()` — Done return key + resign on `.editingDidEndOnExit` (also forwarded on `LMKTextField`) |
| `UIViewController+LMKKeyboardDismiss` | `lmk_dismissKeyboardOnTap()` — tap outside a field dismisses the keyboard; `cancelsTouchesInView = false` so control taps still land |

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
| `LMKPhotoBrowserViewController` | `final class` | Full-screen photo browser with zoom, swipe, delete. Upgrades a cell from `UIImageView` to `PHLivePhotoView` when `photoLivePhoto(at:)` resolves to a non-nil `PHLivePhoto` — still image shows immediately; long-press plays the paired video. Live cells render a `livephoto` + "LIVE" capsule under the action ("…") button that fades during playback. Cell reuse guarded |
| `LMKPhotoBrowserConfig` | `enum` | Shared configuration constants (e.g. `interPageSpacing`) |
| `LMKPhotoCropViewController` | `final class` | Square crop editor with pan/zoom |
| `LMKPhotoPickCropCoordinator` | `final class` | Pick → square-crop → store flow for one photo via permission-free `PHPicker`. Storage injected as `(UIImage) -> String?`; host retains the coordinator for the flow's duration (picker + crop reference their delegates weakly through it) |
| `LMKSinglePhotoViewer` | `final class` | One-image adapter for `LMKPhotoBrowserViewController` (data source + delegate in one object). Optional subtitle and action-button callback; retain while the browser is up |
| `LMKPhotoGridViewController` | `final class` | Photo grid with pinch-to-zoom columns, sort, content mode toggle, browser integration. Cells show a small `livephoto` SF Symbol badge when `photoGridIsLivePhoto(at:)` returns true; paired `PHLivePhoto` is forwarded to the browser via `photoGridLivePhoto(at:) async` |
| `LMKPhotoEXIFService` | `nonisolated enum` (static) | Date + GPS extraction from UIImage or PHPickerResult. Date lookup walks EXIF (`DateTimeOriginal` / `DateTimeDigitized`), TIFF (`DateTime`), IPTC (`DateCreated` + `TimeCreated`, `DigitalCreationDate` + `DigitalCreationTime`), and the XMP packet (`xmp:CreateDate`, `xmp:DateCreated`, `xmp:ModifyDate`, `photoshop:DateCreated`) in capture-fidelity order. Recovers a date for screenshots and Lightroom / Photoshop / Capture One exports where EXIF has been stripped but another container retains the original timestamp |

**Live Photo data-source methods** (all optional, default to no-op):

| Protocol | Method | Role |
|----------|--------|------|
| `LMKPhotoGridDataSource` | `photoGridIsLivePhoto(at:) -> Bool` | Show LIVE badge on grid cell |
| `LMKPhotoGridDataSource` | `photoGridLivePhoto(at:) async -> PHLivePhoto?` | Forwarded to the browser when the grid presents it |
| `LMKPhotoBrowserDataSource` | `photoLivePhoto(at:) async -> PHLivePhoto?` | Swap the browser cell to `PHLivePhotoView` |

Paired-file storage (still JPG + video MOV) is the caller's responsibility — LumiKit takes a pre-assembled `PHLivePhoto`. Hosts typically use `PHLivePhoto.request(withResourceFileURLs:)` to build one from disk.

### Pickers (`Components/Pickers/`)

| Component | Type | Purpose |
|-----------|------|---------|
| `LMKDatePickerHelper` | `enum` (static) | Date picker presentation via `LMKActionSheet` — single date (past/future), date range with live enforcement, single-calendar range picker (`presentCalendarRangePicker`: UICalendarView multi-date selection renders the whole range; nothing is selected until the first tap sets the start, a later tap sets the end, an earlier tap re-anchors, and any tap once a full range exists resets to begin a new selection; `onConfirm` fires only when something is selected), date with text field. Configurable strings, auto-clamping |

### Utilities (`Utilities/`)

| Utility | Purpose |
|---------|---------|
| `LMKDeviceHelper` | Device type (`.iPhone`, `.iPad`, `.macCatalyst`), screen size classification, notch detection |
| `LMKKeyboardObserver` | Keyboard show/hide observer with height + animation info |
| `LMKImageUtil` | SF Symbol creation (`makeSymbolImage` with background), `CVPixelBuffer` to JPEG conversion, `encodeJPEG(_:maxDimension:quality:)` — `nonisolated` downsample + opaque RGBX (`.noneSkipLast`) re-render + `CGImageDestination` encode, so JPEGs stay 3-channel (no ImageIO "AlphaPremulLast" double-memory path) and EXIF orientation is baked into the pixels |
| `LMKDominantColorExtractor` | RGB-histogram color extraction. `dominantColor(from:ignoringTransparent:strategy:)` returns one color: `.modal` (default, densest bucket = subject identity), `.average` (mean = gradient vibe, muddy for subjects), `.vibrant` (most saturated bucket with population tie-breaker = accent color, drops < 0.5% buckets, falls through to modal for grayscale). `dominantColors(from:count:ignoringTransparent:)` returns a top-N palette by frequency. Pass a subject-lifted PNG with `ignoringTransparent: true` (alpha threshold drops semi-transparent edges); raw photos use the default and a 20% border-ring crop. Always uses `kCGImageAlphaPremultipliedLast` — `.last` (unpremultiplied) is rejected by `CGBitmapContext` on iOS |
| `LMKMarkdownRenderer` | Markdown-to-attributed-string: `render()` for inline (bold/italic), `renderFull()` for long-form content (headings, lists, fenced code blocks, GFM tables, `\n` preserved; code and tables in a monospaced font), `makeInlineTextView` |
| `LMKSceneUtil` | Key window and connected scene retrieval |

---

## Error Handling

- **`LMKErrorHandler`** for user-facing errors — supports severity-based presentation:
  - `.info` -> info toast
  - `.warning` -> alert with OK
  - `.error` -> toast (transient) or alert with retry (recoverable)
  - `.critical` -> always alert, retry if available
- All presentation methods auto-log via `LMKLogger`
- **`LMKAlertPresenter`** for generic alerts, action sheets, and single-text-field prompts (`presentTextInput`: save/cancel alert that hands back the field's text verbatim; `Strings` includes a configurable `save` title)
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
- `overrideUserInterfaceStyle = .dark` forces dark appearance for colors, materials, and vibrancy
- `preferredStatusBarStyle = .lightContent` is explicit (safer than relying on system inference from interface style)
- `modalPresentationCapturesStatusBarAppearance = true` is required for modally presented VCs to control the status bar; without it, the **presenting** VC's status bar style is used

**UINavigationController gotcha**: UIKit asks the **container** (not the child) for `preferredStatusBarStyle`. If a forced-dark VC is embedded in a navigation controller, either subclass the nav controller and override `childForStatusBarStyle` to return `topViewController`, or set `navigationBar.barStyle = .black` to force light status bar content.

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

*Optimized for Claude Code. Run `/doc-sync` to refresh file counts and stats.*
