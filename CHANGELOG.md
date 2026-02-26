# Changelog

All notable changes to LumiKit will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.0] - 2026-02-25

### Added

#### Components
- **LMKUserTipView** — Onboarding tip component with centered or pointed (arrow) styles, tap to dismiss
- **LMKFloatingButton** — Draggable floating action button with edge snapping and optional badge
- **LMKCardPageController** — Base class for card-embedded navigation pages with header, title, and multi-page slide navigation
- **LMKCardPanelController** — Centered floating card panel in its own overlay window with shadow and slide animation
- **LMKCardPageLayout** — Shared layout constants for card page controllers
- **LMKCardPanelLayout** — Shared layout constants for card panel controllers
- **LMKBottomSheetController** — Base class for bottom sheet presentation with shared dimming, container, animation, and dismiss
- **LMKEnumSelectionBottomSheet** — Bottom sheet for selecting from an enum's cases
- **LMKDatePickerHelper** — Date picker presentation via `LMKActionSheet` (single date, date range, date with text field)

#### Core Utilities
- **LMKLogStore** — Thread-safe in-memory ring buffer for log entries with FIFO eviction and `OSAllocatedUnfairLock` concurrency
- **LMKLogLevel** — Log level enum (`debug`, `info`, `warning`, `error`)
- **LMKLogEntry** — Sendable log entry struct with timestamp, level, category, and message
- **LMKOverscrollFooterHelper** — Positions footer below scroll content, revealed on overscroll

#### Photo
- **LMKPhotoBrowserConfig** — Namespaced constants for photo browser (replaces bare module-level constants)

#### Debug Tools (DEBUG builds only)
- **LMKNetworkLogger** — Network debugging system with URLProtocol-based request/response interception, thread-safe ring buffer storage, and LMKLogger-style static API (`configure()`, `enable()`, `records`, `clearRecords()`)
- **LMKNetworkRequestStore** — Thread-safe ring buffer for network request records with FIFO eviction using `OSAllocatedUnfairLock`
- **LMKNetworkRequestRecord** — Sendable struct capturing HTTP request/response details with formatted display properties and JSON pretty-printing
- **URLSessionConfiguration.withNetworkLogging()** — Extension method for injecting network logging into custom URLSession configurations
- **LMKNetworkHistoryViewController** — List view for captured network requests with auto-refresh and newest-first ordering
- **LMKNetworkDetailViewController** — Detail view with formatted request/response headers and bodies (50k character truncation for large payloads)
- **LMKNetworkRequestStoreTests** — 8 tests covering basic functionality, ring buffer FIFO eviction, and thread safety (concurrent additions/reads/updates)

#### Technical Notes

**Swift 6 Concurrency Workaround**: Network debugging uses `#if !SWIFT_PACKAGE` conditional compilation due to Swift 6 strict concurrency limitations. URLProtocol subclasses cannot conform to URLSessionDelegate (Sendable requirement conflicts with non-NSObject inheritance). The implementation is:
- **Disabled** when building LumiKit as a standalone Swift package (clean builds in CI)
- **Enabled** when imported by Xcode projects with `SWIFT_APPROACHABLE_CONCURRENCY = YES` build setting

Apps using network debugging must set `SWIFT_APPROACHABLE_CONCURRENCY = YES` in Xcode build settings. See [FIXES.md](../FIXES.md) for detailed technical analysis and attempted alternatives.

### Changed
- **LMKLogger** — Added opt-in in-memory log store via `enableLogStore(maxEntries:)` / `disableLogStore()`, moved from `Data/` to new `Log/` subfolder
- **LMKLogger.LogCategory** — Added public `name` property for log store category tracking
- **LMKActionSheet** — Added support for multi-level page structure navigation
- **LMKProgressViewController** — Enhanced with determinate/indeterminate modes and progress bar
- **DesignSystem** — Restructured into `Tokens/`, `Themes/`, and `Factories/` subfolders
- **Components** — Extracted bottom sheet base class, organized into `BottomSheet/` and `Pickers/` subfolders
- **LMKShadowTheme** — Shadow configuration now uses nested `LMKShadowConfig` structs instead of flat properties for cleaner API
- **Test suite** — Expanded from 284 to 566 tests (84 Core + 475 UI + 7 Lottie)
- **Source files** — Increased from 79 to 95 files (16 new files including 6 debug infrastructure)
- Various API improvements and bug fixes across components

### Removed
- **lmk_setEdgesEqualToSuperView()** — Removed deprecated method (renamed to `lmk_setEdgesEqualToSuperview()` in 0.1.0)
- **LMKShadowTheme flat properties** — Removed backward compatible flat properties (`cellCardRadius`, `cardOffset`, etc.); use nested config structs instead (`cellCard.radius`, `card.offset`)

### Fixed
- **LMKCardPanelController** — Fixed gesture handling
- **LMKUserTipView** — Optimized arrow layer rendering
- **LMKEmptyStateView** — Updated layout for better content alignment
- **LMKPhotoCropViewController** — Fixed background color handling

## [0.1.0] - 2026-02-18

### Added

#### LumiKitCore
- **LMKLogger** — Structured logging with categories (`.general`, `.data`, `.ui`, `.network`, `.error`)
- **LMKDateHelper** — Date calculation, comparison, and formatting helpers
- **LMKDateFormatterHelper** — Cached date formatters for performance
- **LMKFormatHelper** — Number and string formatting utilities
- **LMKFileUtil** — Temporary file generation and directory cleanup
- **LMKURLValidator** — URL validation and sanitization
- **LMKConcurrencyHelpers** — Off-main-thread Codable encode/decode
- **Collection+LMK** — Safe subscript, grouping, and collection utilities
- **String+LMK** — String manipulation and validation extensions
- **NSAttributedString+LMK** — Attributed string building helpers

#### LumiKitUI — Design System
- **LMKThemeManager** — Centralized theme configuration with full token customization
- **LMKColor** — Semantic color tokens (primary, background, text, status colors)
- **LMKTypography** — Font family, sizes, weights, line heights, letter spacing
- **LMKSpacing** — 4pt base unit grid (xs through xxl) with device-scaled padding
- **LMKCornerRadius** — Small, medium, large, pill corner radius tokens
- **LMKAlpha** — Opacity tokens (overlay, disabled, strong)
- **LMKShadow** — Shadow presets (cellCard, card, button, small)
- **LMKLayout** — Device-aware layout constants (touch targets, icon sizes, heights)
- **LMKAnimationHelper** — Animation timing with Reduce Motion support
- **LMKBadgeTheme** — Badge dimension tokens
- **LMKLabelFactory** — Styled label creation (heading, body, caption, small, scientific name)
- **LMKButtonFactory** — Pre-styled buttons (primary, secondary, destructive, warning)
- **LMKCardFactory** — Card views with shadow and corner radius

#### LumiKitUI — Components
- **LMKActionSheet** — Custom bottom-sheet action sheet with design-token styling
- **LMKBadgeView** — Notification count, status dot, or custom text badge
- **LMKBannerView** — Persistent notification bar with optional action and dismiss
- **LMKCardView** — Card container with shadow, corner radius, content insets
- **LMKChipView** — Tag/filter chip (filled/outlined) with optional tap handler
- **LMKDividerView** — Pixel-perfect separator (horizontal/vertical)
- **LMKEmptyStateView** — Empty state with icon, title, message, action button
- **LMKEnumSelectionBottomSheet** — Bottom sheet for selecting from enum cases
- **LMKGradientView** — CAGradientLayer-backed view with 4 direction options
- **LMKLoadingStateView** — Loading indicator with optional message
- **LMKProgressViewController** — Progress indicator view controller
- **LMKSearchBar** — Search bar with configurable placeholder and cancel text
- **LMKSkeletonCell** — Skeleton loading placeholder cell
- **LMKToastView** — Auto-dismissing toast notification

#### LumiKitUI — Controls
- **LMKButton** — Base button with closure-based tap handling and press animation
- **LMKSegmentedControl** — Custom segmented control with closure callbacks
- **LMKTextField** — Text field with validation states, helper text, leading icon
- **LMKTextView** — Multi-line text input with placeholder and character limit
- **LMKToggleButton** — Toggle button with on/off states

#### LumiKitUI — Photo
- **LMKPhotoBrowserViewController** — Full-screen photo browser with zoom and swipe navigation
- **LMKPhotoCropViewController** — Photo cropping with 6 aspect ratio options
- **LMKPhotoEXIFService** — EXIF date and GPS extraction

#### LumiKitUI — Other
- **LMKAlertPresenter** — Generic alert and action sheet presentation
- **LMKErrorHandler** — Severity-based error presentation with auto-logging
- **LMKShareService** — Share sheet wrapper with popover support
- **LMKSharePreviewViewController** — Image preview with share and save actions
- **LMKQRCodeGenerator** — CoreImage QR code generation
- **LMKHapticFeedbackHelper** — Haptic feedback helpers (light, medium, heavy, success, error)
- **LMKDeviceHelper** — Device type detection (iPhone, iPad, Mac Catalyst)
- **LMKKeyboardObserver** — Keyboard show/hide notification observer
- **LMKImageUtil** — SF Symbol creation and pixel buffer conversion
- **LMKSceneUtil** — Scene and screen utilities
- 14 UIKit extensions with `lmk_` prefix (UIColor, UIImage, UIView, UIStackView, UIButton, UIControl, UIViewController, UITableViewCell, UITextField)

#### LumiKitLottie
- **LMKLottieRefreshControl** — Lottie-powered pull-to-refresh control

#### Example App
- 15-page interactive catalog app demonstrating all components
- XcodeGen-based project setup (`Example/project.yml`)
- Custom `ExampleTheme` showing how to implement `LMKTheme`
- Embedded skeleton shimmer demo, live QR code generator, photo browser with sample images

#### Infrastructure
- Swift 6.2 strict concurrency with `defaultIsolation: MainActor` on UI/Lottie targets
- 79 source files across 3 targets
- 284 tests (61 Core + 223 UI) across 70 suites
- Builds on iOS 18+, Mac Catalyst 18+, macOS 15+
- All configurable strings use module-level `nonisolated(unsafe)` vars for localization
- MIT License

[0.1.0]: https://github.com/Luminoid/LumiKit/releases/tag/0.1.0
