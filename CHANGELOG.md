# Changelog

All notable changes to LumiKit will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
