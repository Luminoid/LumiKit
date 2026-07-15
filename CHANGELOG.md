# Changelog

All notable changes to LumiKit will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- **LMKSegmentedPageController** — Base class for a segmented tab container that pages between child view controllers with an interactive finger-tracking pan. Subclasses override `makePages()`, `usesFullWidthSwipe(forPageAt:)` (full-width vs edge-only pan, for pages that own interior horizontal drags), and `didChangePage(to:)`; `setPage(_:animated:)` slides for taps and deep links. The top `LMKSegmentedControl` is installed via the overridable `installSegmentedControl()` (default: nav title view).
- **LMKMarkdownRenderer code & tables** — `renderFull()` renders fenced code blocks and GFM tables in a monospaced font, so AI chat responses stay readable. Table columns align via tab stops with a full-width rule; bullet markers and spacing are normalized.
- **LMKDatePickerHelper.presentCalendarRangePicker** — Single-calendar range selection built on `UICalendarView` multi-date selection: the first tap sets the start, a later tap sets the end, an earlier tap re-anchors, and any tap once a full range exists begins a new selection. `onConfirm` fires only when something is selected.
- **LMKAlertPresenter.presentTextInput** — Single-text-field alert with save/cancel for name, title, and identifier prompts. The save action hands back the field's text verbatim; trimming and empty checks stay with the caller. `Strings` gains a configurable `save` title.
- **LMKCheckboxCell** — Check-off row for to-dos and checklists: checkbox + strike-through title, `configure(title:isDone:)`, `onToggle` callback. The checkbox hit area expands to the minimum touch target; done state is exposed via `accessibilityValue` and the `.selected` trait.
- **LMKLayout.iconCircle** — 36pt token for the tinted icon circle behind a list-row symbol, with the matching `LMKLayoutTheme` property.
- **UITableViewCell.lmk_configureIconListRow** — One-call standard detail-list row: SF Symbol in a tinted circle (`LMKLayout.iconCircle`), bodyMedium title, caption subtitle, disclosure indicator, and the LumiKit highlight.
- **Keyboard dismiss extensions** — `UITextField.lmk_dismissKeyboardOnReturn()` (Done return key + resign on `.editingDidEndOnExit`, forwarded on `LMKTextField`) and `UIViewController.lmk_dismissKeyboardOnTap()` (tap anywhere outside a field dismisses the keyboard without swallowing control taps).
- **LMKPhotoPickCropCoordinator** — Pick → square-crop → store flow for a single photo using a permission-free `PHPicker`. Storage is injected as a `(UIImage) -> String?` closure; the host retains the coordinator for the flow's duration.
- **LMKSinglePhotoViewer** — One-image data source + delegate adapter for `LMKPhotoBrowserViewController`, with optional subtitle and action-button callback.
- **LMKImageUtil.encodeJPEG(_:maxDimension:quality:)** — `nonisolated` downsample + opaque RGBX re-render + `CGImageDestination` encode, so JPEGs stay 3-channel (avoids ImageIO's "AlphaPremulLast" double-memory path) and EXIF orientation is baked into the pixels.

### Fixed

- **LMKPageIndicator** — Display-only when no `pageChangedHandler` is set: taps and VoiceOver increment/decrement no longer move `currentPage` (and the `.adjustable` trait is only advertised while a handler is wired). Previously a tap moved the highlighted dot even with nobody listening, silently desyncing the indicator from the page a controller-driven host was actually showing (e.g. Plantfolio's onboarding; Metamer hit the same trap and has since dropped its dots entirely). Hosts that wire a handler (Petfolio, Example app) are unaffected.
- **LMKSegmentedControl** — The default height constraint yields to host overrides (high priority instead of required), and the hit area inflates to the 44pt minimum touch target.
- **LMKCardView** — Stops double-rounding the inset `contentView`; the outer layer owns the corner radius.

### Infrastructure

- 891 → 984 tests; 112 → 119 source files.
- Example app: new pages for Segmented Pages, Checkbox Cell, Pick & Crop (pick-crop coordinator + single photo viewer), Icon List Row, and Keyboard Dismiss; calendar range picker, markdown code/table, and text-input alert demos added to existing pages. 43 → 51 interactive pages; catalog reorganized from 7 into 9 sections (Lists & Cells and Navigation & Paging split out of Components and Extensions).

## [0.9.0] - 2026-05-25

### Added

- **LMKSlider** — Tokenized continuous or step-snapped slider with optional caption + live value readout.
- **`UIColor(lmk_hex: UInt32)`** — Compile-time-validated 24-bit hex literal initializer.
- **`UIColor.lmk_dynamic(lightHex:darkHex:alpha:)`** — One-line trait-aware light/dark color, used by Monolith 0.4.0+'s `ThemeGenerator`.

### Changed

- **LMKPhotoBrowserCell / LMKPhotoGridCell** — LIVE-badge styling moved to design-system tokens.

### Fixed

- **LMKPhotoBrowserCell / LMKPhotoGridCell** — LIVE-badge corner radius pinned to a fixed-height constant, fixing a one-frame square flash when the cell's `layoutSubviews` ran before the badge's bounds resolved.
- **LMKSharePreviewViewController** — Save-to-Photos `Task` stored and cancelled in `deinit`, preventing an in-flight save leak on dismiss.

### Infrastructure

- 873 → 891 tests; 111 → 112 source files.

## [0.8.0] - 2026-05-15

### Added

- **`LMKCornerRadius.xxl`** — 40pt corner-radius token for modal-card surfaces.
- **LMKHighlightable** — Public protocol unifying `lmk_applyCustomHighlight(highlighted:animated:)` across `UITableViewCell` and `UICollectionViewCell` (both conform retroactively). Route from `setHighlighted` / `setSelected` on table cells, `isHighlighted` / `isSelected` `didSet` on collection cells.
- **LMKCountdownConfirmationViewController** — Custom modal dialog VC backing `LMKCountdownConfirmation.present(...)`; public for testing only.

### Changed

- **LMKCountdownConfirmation** — Rebuilt on a custom `UIViewController` (no `UIAlertController`) so the live countdown title renders identically on iOS and Mac Catalyst. `LMKCornerRadius.xxl` card, capsule buttons in a 48pt-height stack, hairline edge via a `LMKColor.divider` outer view inset by 1pt.
- **Cell highlight overlay** — Dark mode uses translucent white (was black-on-dark, invisible on already-dark cards). Overlay is installed pre-animation so corner radius resolves on the first frame, fixing a one-frame square flicker.

### Fixed

- **LMKPhotoBrowserCell** — Pinch-to-zoom anchors at the gesture focal point (was view center); edge pans at zoom > 1 hand off to the paging scroll view by swapping `viewForZooming`. LIVE badge plays on Mac Catalyst pointer hover.

## [0.7.1] - 2026-05-11

### Added

- **Swift Package Index integration** — Added `.spi.yml` enabling SPI-hosted DocC at `https://swiftpackageindex.com/Luminoid/LumiKit/documentation` for `LumiKitCore`, `LumiKitUI`, `LumiKitNetwork`, and `LumiKitLottie`. README now shows SPI Swift-versions + platforms badges.

## [0.7.0] - 2026-05-10

### Added

- **LMKDominantColorExtractor** — Histogram-backed dominant color extraction. Downsamples to a 40×40 grid, bins pixels into a 6×6×6 RGB histogram (216 buckets). Public APIs:
  - `dominantColor(from:ignoringTransparent:strategy:)` returns a single `UIColor?`. Three strategies:
    - `.modal` (default) — densest bucket. Subject identity (black cat → black, British Blue → cool grey)
    - `.average` — mean of every sampled pixel. Captures the overall "vibe" of gradients; muddy for subject photos
    - `.vibrant` — most saturated bucket with a population tie-breaker. Picks the accent color (small red flower against grey rocks → red, not grey). Drops buckets covering < 0.5% of samples to avoid single-pixel noise. Falls through to modal for grayscale images
  - `dominantColors(from:count:ignoringTransparent:)` returns up to N colors as a palette in descending frequency order. Returns fewer than `count` when the image has fewer non-empty buckets (a solid-color image returns one color)
  - `ignoringTransparent: true` drops pixels with alpha < ~0.9 — pair with a subject-lifted PNG (e.g. from `VNGenerateForegroundInstanceMaskRequest`) for hard-edge subject accuracy. `false` (default) drops a 20% border ring instead so typical backgrounds contribute less than the centered subject
- **Live Photo support in `LMKPhotoGrid*` + `LMKPhotoBrowser*`** — Grid cells render a small `livephoto`-symbol LIVE badge when `photoGridIsLivePhoto(at:)` returns true. The browser upgrades a cell from `UIImageView` to `PHLivePhotoView` (same constraints, still visible first) when `photoLivePhoto(at:)` (or the grid-forwarded `photoGridLivePhoto(at:)`) resolves to a non-nil `PHLivePhoto`. Live browser cells show a `livephoto` + "LIVE" capsule stacked directly below the action ("…") button (matching the iOS Photos indicator placement) — the badge fades out during active playback and returns on end, driven by `PHLivePhotoViewDelegate`. All new data-source methods have default implementations returning `false`/`nil`, so existing conformers don't need changes. Long-press playback is delegated to `PHLivePhotoView`'s built-in recognizer. Cell reuse is guarded — loads that resolve after the cell has paged away are dropped
- **LMKSegmentedControl `itemSpacing`** — New public property controlling the gap between adjacent segments when scrollable. Default is `LMKSpacing.medium` (12pt), matching the previous hardcoded value. Takes effect after `makeScrollableContainer()` is called; non-scrollable mode always uses 0 spacing since the sliding pill spans full segment bounds. `intrinsicContentSize` accounts for `itemSpacing` in scrollable mode
- **LMKNavigationBar `setRightAccessoryView(_:)` / `setLargeTitleAccessoryView(_:)`** — Two new APIs for non-tappable inline accessories (sync indicators, status icons). `setRightAccessoryView(_:)` parks a view immediately to the left of the right-items stack and survives later `setRightItems(_:)` calls (the accessory lives outside the items stack). `setLargeTitleAccessoryView(_:)` hangs a view off the trailing edge of the large title text — the iOS Mail / Notes pattern — driven by raising the large title's content-hugging priority to `.required` so the accessory tracks the actual text width, not the row width. Pass `nil` to either to remove the existing accessory
- **LMKPhotoEXIFService IPTC + XMP date fallbacks** — `extractDate(from:)` now walks five containers in capture-fidelity order (was: two): EXIF `DateTimeOriginal` → EXIF `DateTimeDigitized` → TIFF `DateTime` → IPTC `DateCreated` / `TimeCreated` → IPTC `DigitalCreationDate` / `DigitalCreationTime`, then falls through to the XMP packet (`xmp:CreateDate`, `xmp:DateCreated`, `xmp:ModifyDate`, `photoshop:DateCreated`). XMP dates parse with ISO 8601 (with optional fractional seconds) and date-only formats. Recovers a date for screenshots, Lightroom / Photoshop / Capture One exports, and other photos where EXIF is stripped but another container still holds the original capture timestamp

### Changed

- **LMKSegmentedControl `fitsSegmentsToContent` + `makeScrollableContainer()` compose** — The two modes now work together. Previously each label got both a fit-mode exact-width constraint (`==`) and a scrollable min-width floor (`>=`), which was unsatisfiable for short labels. In combined mode the exact-width wins (using `itemPadding`), and `scrollableItemPadding` is suppressed. Setters for `isScrollable` and `scrollableItemPadding` now reapply constraints on change, and distribution stays `.fill` whenever segments have individual widths
- **LMKSegmentedControl `scrollableItemPadding`** — Now triggers a constraint refresh when mutated (previously the initial value baked into `makeScrollableContainer()` was never revisited)

### Fixed

- **LMKSegmentedControl non-fit scrollable segment widths** — Each scrollable segment is now pinned to `max(selectedFontRefWidth, minimumTouchTarget) + scrollableItemPadding*2` (exact) instead of the live label intrinsic width with a touch-target floor. Previously the selected segment rendered visibly wider than its neighbors because the selected-state font (`bodyMedium`, 16pt) produced a larger intrinsic width than the unselected-state font (`subbodyMedium`, 14pt). Widths now stay stable as selection moves between labels

### Removed

- **LMKSegmentedControl `numberOfSegments`** — The CHANGELOG for v0.5.0 had announced removal of this UISegmentedControl-compat shim, but the property was still present as a passthrough to `items.count`. Now actually removed.

## [0.6.0] - 2026-04-19

### Added

- **LMKFilterChipBar** — Horizontal scrolling single-select chip row built on `LMKChipView`. Optional "All" chip (via `allTitle`) is prepended and clears the filter. `configure(allTitle:filterTitles:style:)` rebuilds the chips, `setSelectedIndex(_:)` seeds selection silently, and `selectionChangedHandler: ((Int?) -> Void)` fires with the filter index or `nil` for "All" / no selection
- **LMKCountdownConfirmation** — Confirmation alert with a timed countdown on the destructive button. The confirm button is disabled for a configurable number of seconds (default 3) with a live countdown in the title, preventing accidental taps on critical actions
- **LMKNavigationController** — `UINavigationController` subclass that keeps the interactive edge-swipe-to-go-back gesture working when the system navigation bar is hidden. Installs itself as the pop gesture's delegate and enables the gesture whenever the stack has 2+ view controllers (disabled on root to avoid UIKit's stuck-stack state). Pairs with `LMKNavigationBar`-based apps that hide the system nav bar
- **LMKEnumSelectionBottomSheet `presentMultiSelect(...)`** — New API for multi-value selection. Tapping a row toggles its checkmark without dismissing the sheet; selections are committed via an explicit Done button (cancel/dimming-tap discards). Initial selection passed as `Set<T>`, callback receives final `Set<T>`. Optional `doneTitle` parameter (defaults to `LMKAlertPresenter.strings.ok`). Existing single-select `present(...)` API unchanged
- **LMKNavigationBar item enabled state** — New `setLeftItemEnabled(at:_:)` and `setRightItemEnabled(at:_:)` toggle per-item enabled state. Disabled items render at `LMKAlpha.disabled` and stop firing their action. Out-of-range indices are a no-op
- **LMKSegmentedControl `fitsSegmentsToContent`** — When `true`, each segment sizes to its own content width (measured at the wider selected-state font so widths stay stable as labels swap fonts on selection) plus `itemPadding` on each side, and the control hugs its content horizontally instead of stretching in a `.fill` parent stack. Useful when labels have very different widths (e.g. a rating control from "★" to "★★★★★"). Default `false`
- **LMKPhotoGridViewController empty state icon** — New `emptyIcon: String?` parameter on `LMKPhotoGridStrings` (default `"photo.on.rectangle.angled"`) for the SF Symbol shown alongside the empty message

### Changed

- **LMKSegmentedControl `selectedSegmentIndex`** — Assigning `-1` (or any out-of-range value) now represents "no selection": the sliding indicator is hidden and every label renders in the unselected style, matching `UISegmentedControl.noSegment` semantics. Previously, `-1` crashed with "Index out of range" in `moveIndicator`
- **LMKPhotoGridViewController empty state** — Replaced plain label with `LMKEmptyStateView` (`.fullScreen` style) so the empty grid shows an icon + message instead of a bare centered label

### Fixed

- **LMKSegmentedControl** — Guard both bounds of `selectedSegmentIndex` before subscripting `segmentLabels` in `moveIndicator` and the drag gesture handler (cancel the drag if no segment is selected); previously the upper bound was checked but `-1` crashed

## [0.5.0] - 2026-04-07

### Added

- **LMKNavigationBar** — Custom navigation bar with design-token styling. Supports large title mode (bold, left-aligned, separate row) and standard inline mode (centered title). Configurable back button, left/right bar items (`LMKNavigationBarItem`), separator, and full appearance customization (background, tint, title font/color). Uses `pinToTop(of:)` for easy layout
- **LMKPhotoGridViewController** — Photo grid with square cells, pinch-to-zoom column control (2–6 columns), sort by date (newest/oldest), content mode toggle (aspect fill/fit), and integrated photo browser navigation. Delegates: `LMKPhotoGridDataSource`, `LMKPhotoGridDelegate`
- **LMKSwitch** — Custom toggle switch replacing `UISwitch`. Features a rounded track with sliding circular thumb, spring animation, haptic feedback, `isOn`/`setOn(_:animated:)` API, `valueChangedHandler` closure, and VoiceOver accessibility
- **LMKPageIndicator** — Custom page indicator replacing `UIPageControl`. Supports optional `expandsActiveDot` (default `false`) to expand the active dot into a pill shape with spring animation. `maxVisibleDots` windowing for many pages. `pageChangedHandler` and VoiceOver increment/decrement
- **LMKButton styles** — Added `.ghost(UIColor)` (text-only, no background) and `.iconOnly(UIColor)` (circular icon button) styles
- **LMKButton loading** — `isLoading` property shows activity indicator and disables interaction
- **LMKButtonFactory** — Added `ghost(role:title:)` and `iconOnly(role:iconName:)` factory methods
- **LMKMarkdownRenderer.renderFull()** — Long-form markdown rendering with headings (H1–H4), ordered/unordered lists, horizontal rules, and preserved line breaks
- **LMKActionSheet `isSelected`** — Action items support `isSelected: true` to display a trailing checkmark, with `.selected` accessibility trait
- **LMKTextView `minimumHeight`** — Configurable minimum height property (default 100pt) that updates the height constraint dynamically
- **LMKKeyboardInsetHelper** — Keyboard-aware scroll view inset management
- **LMKShareResult** — Result enum for share operations: `.completed(ActivityType?)`, `.cancelled`, `.failed(Error)`
- **LMKSharePreviewDelegate `didFailToShare` / `didFailToSave`** — New delegate methods for share and save error handling

### Changed

- **LMKSegmentedControl** — **Breaking**: Fully rewritten as custom `UIControl` (no longer a `UISegmentedControl` subclass). Features sliding pill indicator with spring animation, `LMKColor.primary` fill, haptic feedback, and dark mode support. New properties: `cornerStyle` (`.capsule` default, `.rounded`), `itemPadding`, `makeScrollableContainer()`. API: `init(items: [String])`, `selectedSegmentIndex`, `valueChangedHandler`. Removed `didValueChangeHandler`, `numberOfSegments` (use `items.count`), `apportionsSegmentWidthsByContent`, `init(items: [Any]?)` compatibility shim
- **LMKButton** — Filled and outlined styles now use `cornerStyle = .capsule` (pill shape) instead of `LMKCornerRadius.small`
- **LMKControlScrollView** — Removed. `LMKSegmentedControl.makeScrollableContainer()` now returns `UIScrollView` directly
- **Source files** — Increased from 104 to 106 files (97 test files)
- **Test suite** — Expanded from 686 to 803 tests (76 Core + 65 Network + 655 UI + 7 Lottie). New: LMKNavigationBar 29, LMKSwitch 7, LMKPageIndicator 8, LMKButton styles 5, LMKPhotoGrid 29, LMKKeyboardInsetHelper 6, updated LMKSegmentedControl 10, and additional coverage across components
- **LMKNavigationBar back button** — Refined chevron from 20pt semibold to 17pt medium to match system navigation bar
- **Example app** — Expanded from 33 to 40 interactive pages (new: Navigation Bar, Photo Grid, and others). Added `isSelected` checkmark demo to Action Sheet page. Reorganized into subdirectories by section
- **LMKShareService.shareImage** — **Breaking**: Completion now receives `LMKShareResult` instead of `UIActivity.ActivityType?`, correctly distinguishing completed/cancelled/failed states
- **LMKSharePreviewViewController** — **Breaking**: Removed internal toast logic for share and save success/error. All feedback is now entirely delegate-driven via `didShareWith`, `didFailToShare`, `sharePreviewDidSave`, and `didFailToSave`. Removed `saveError` and `saveSuccess` from `LMKSharePreviewStrings`
- **Package.swift** — Added `LMK_ENABLE_NETWORK_LOGGING` define to `LumiKitNetworkTests` target so `URLSessionConfiguration+LMKDebug` tests run in debug builds

### Fixed

- **LMKOverscrollFooterHelper** — Fixed footer inset calculation

## [0.4.0] - 2026-03-22

### Added

- **LMKSegmentedControl** — `isScrollable` support with `LMKControlScrollView` for horizontally scrollable segments
- **LMKButton** — `lmk_singleLineShrinkToFit` for auto-shrinking single-line button text

### Changed

- **LMKProgressViewController** — Updated API surface
- **LMKEnumSelectionBottomSheet** — Type-erased to work around Swift 6.2 WMO compiler crash
- **LMKDatePickerHelper** — TextField return handling
- **Test suite** — Expanded from 615 to 686 tests (76 Core + 61 Network + 542 UI + 7 Lottie), 89 test files (up from 86)

### Fixed

- Thread safety, memory retention, and code quality improvements across all targets
- Package.swift trailing comma formatting

## [0.3.0] - 2026-03-13

### Added

#### Components
- **LMKScrollStackViewController** — Base class for scrollable vertical stack layout with configurable spacing, insets, keyboard dismiss, and safe area handling
- **LMKNavigationDirection** — Enum for navigation direction semantics (forward/backward)
- **LMKMarkdownRenderer** — Markdown-to-attributed-string renderer with `makeInlineTextView` helper

#### Controls
- **LMKButtonFactory role-based API** — `LMKButtonRole` enum with `filled(role:)` / `outlined(role:)` (replaced 12 individual methods)

#### Utilities
- **LMKImageUtil.makeSymbolImage** — SF Symbol rendering with optional background circle
- **LMKSkeletonCell.startShimmers(in:)** — Static convenience for triggering shimmer on visible skeleton cells

#### Infrastructure
- **Git hooks** — Pre-commit hook for SwiftFormat/SwiftLint
- **Makefile** — Added format/lint targets

### Changed

- **LMKBottomSheetController** — Added drag-to-dismiss gesture support
- **LMKTipView** — Added position offset support for fine-tuning tip placement
- **LMKToastView** — Updated visual style
- **LMKShadow** — Added more shadow style options (toast, floating)
- **LMKChipView** — Enhanced with additional configuration options
- **LMKCardPageController** — Improved navigation direction handling
- **SwiftLint/SwiftFormat** — Updated configuration and enforced across all targets
- **Test suite** — Expanded from 566 to 615 tests (76 Core + 8 Network + 524 UI + 7 Lottie)
- **Source files** — Increased from 89 to 100 files (86 test files)
- **Input validation** — Added validation and clamping across multiple components (LMKTextField, LMKTextView, LMKFloatingButton, LMKGradientView)
- **Accessibility** — Improved VoiceOver support across components

### Removed

- **LMKTouchExpandedButton** — Removed in favor of standard UIKit hit testing approaches

### Fixed

- **LMKNetworkDetailViewController** — Fixed copy button not working
- **LMKPhotoCropViewController** — Fixed crop boundary sign calculation
- **LMKLogStore** — Code quality improvement
- **LMKNetworkRequestStore** — Code quality improvement
- **LMKDatePickerHelper** — Fixed date range validation
- **Example app** — Fixed haptics demo, date picker range, about section

## [0.2.0] - 2026-02-25

### Added

#### Components
- **LMKTipView** — Onboarding tip component with centered or pointed (arrow) styles, tap to dismiss
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
- **LMKNetworkLogger** — Network debugging system with URLProtocol-based request/response interception in separate `LumiKitNetwork` target
  - Thread-safe ring buffer storage with LMKLogger-style static API (`configure()`, `enable()`, `records`, `clearRecords()`)
  - URLSessionDataDelegate with serial OperationQueue and ephemeral configuration for Swift 6 strict concurrency compatibility
  - Works correctly in Swift Package Manager builds
- **LMKNetworkRequestStore** — Thread-safe ring buffer for network request records with FIFO eviction using `OSAllocatedUnfairLock`
- **LMKNetworkRequestRecord** — Sendable struct capturing HTTP request/response details with formatted display properties and JSON pretty-printing
- **URLSessionConfiguration.withNetworkLogging()** — Extension method for injecting network logging into custom URLSession configurations
- **LMKNetworkHistoryViewController** — List view for captured network requests with auto-refresh and newest-first ordering
- **LMKNetworkDetailViewController** — Detail view with formatted request/response headers and bodies (50k character truncation for large payloads)

### Changed

- **LMKLogger** — Added opt-in in-memory log store via `enableLogStore(maxEntries:)` / `disableLogStore()`
- **LMKLogger.LogCategory** — Added public `name` property for log store category tracking
- **LMKActionSheet** — Added support for multi-level page structure navigation
- **LMKProgressViewController** — Enhanced with determinate/indeterminate modes and progress bar
- **DesignSystem** — Restructured into `Tokens/`, `Themes/`, and `Factories/` subfolders
- **Components** — Extracted bottom sheet base class, organized into `BottomSheet/` and `Pickers/` subfolders
- **LMKShadowTheme** — Shadow configuration now uses nested `LMKShadowConfig` structs instead of flat properties for cleaner API
- **Test suite** — Expanded from 284 to 566 tests (76 Core + 8 Network + 475 UI + 7 Lottie)
- **Source files** — Increased from 79 to 89 files

### Removed

- **lmk_setEdgesEqualToSuperView()** — Removed deprecated method (renamed to `lmk_setEdgesEqualToSuperview()` in 0.1.0)
- **LMKShadowTheme flat properties** — Removed backward compatible flat properties (`cellCardRadius`, `cardOffset`, etc.); use nested config structs instead (`cellCard.radius`, `card.offset`)

### Fixed

- **LMKCardPanelController** — Fixed gesture handling
- **LMKTipView** — Optimized arrow layer rendering
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
- **LMKSwitchButton** — Toggle button with on/off states

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

[Unreleased]: https://github.com/Luminoid/LumiKit/compare/0.9.0...HEAD
[0.9.0]: https://github.com/Luminoid/LumiKit/compare/0.8.0...0.9.0
[0.8.0]: https://github.com/Luminoid/LumiKit/compare/0.7.1...0.8.0
[0.7.1]: https://github.com/Luminoid/LumiKit/compare/0.7.0...0.7.1
[0.7.0]: https://github.com/Luminoid/LumiKit/compare/0.6.0...0.7.0
[0.6.0]: https://github.com/Luminoid/LumiKit/compare/0.5.0...0.6.0
[0.5.0]: https://github.com/Luminoid/LumiKit/compare/0.4.0...0.5.0
[0.4.0]: https://github.com/Luminoid/LumiKit/compare/0.3.0...0.4.0
[0.3.0]: https://github.com/Luminoid/LumiKit/compare/0.2.0...0.3.0
[0.2.0]: https://github.com/Luminoid/LumiKit/compare/0.1.0...0.2.0
[0.1.0]: https://github.com/Luminoid/LumiKit/releases/tag/0.1.0
