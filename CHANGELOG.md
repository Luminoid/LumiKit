# Changelog

All notable changes to LumiKit will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

Nothing yet. Until 1.0.0 is tagged, changes land in its section below.

## [1.0.0] - Unreleased

LumiKit 1.0 rebuilds the package as a public UI framework: five products, one nomenclature, a struct theme that propagates through the trait system, a `Style` struct on every component, localized strings in four languages, and the current iOS APIs adopted behind availability gates. Every 0.x consumer needs the migration script: read [docs/MIGRATION-1.0.md](docs/MIGRATION-1.0.md), then run `Scripts/migrate-1.0.sh <consumer-dir> --dry-run`.

### BREAKING

#### Products

| Old | New | Why |
|---|---|---|
| `LumiKitNetwork` | `LumiKitDebug` | The URLProtocol logger and its inspector screens ship in one DEBUG-only product |
| Photo browser, grid, crop editor, pick-and-crop coordinator, and share preview in `LumiKitUI` | `LumiKitPhoto` | `LumiKitUI` no longer links PhotosUI for consumers that never show a photo |
| `LumiKitUI` depended on `LumiKitNetwork` | `LumiKitUI` depends on `LumiKitCore` and SnapKit only | Link `LumiKitDebug` yourself, under `#if DEBUG` |
| `LMKLottieRefreshControl.animationBundle` defaulted to `.main` and needed an app-supplied JSON | The package bundles its ring animation, tinted from the theme | Delete the app copy or pass `animation:` for a custom one |

Every product ships `en`, `es`, `zh-Hans`, and `zh-Hant` string tables.

#### Naming

One nomenclature, documented in [CONTRIBUTING.md](CONTRIBUTING.md) and checked by a test. The migration script renames all of these.

| Old | New |
|---|---|
| `LMKConcurrencyHelpers`, `LMKDateHelper`, `LMKDateFormatterHelper`, `LMKFormatHelper`, `LMKFileUtil` | `LMKConcurrency`, `LMKDate`, `LMKDateFormat`, `LMKFormat`, `LMKFile` |
| `LMKAnimationHelper`, `LMKHapticFeedbackHelper`, `LMKDeviceHelper`, `LMKSceneUtil` | `LMKAnimation`, `LMKHaptics`, `LMKDevice`, `LMKScene` |
| `LMKImageUtil`, `LMKDominantColorExtractor`, `LMKQRCodeGenerator` | `LMKImage` (`symbol`, `downsample`, `dominantColor`, `qrCode`); `encodeJPEG(_:maxDimension:quality:)` is `encodeJPEG(_:maxPixelSize:quality:)` and caps in pixels of the image, like `downsample` |
| `LMKAlertPresenter`, `LMKCountdownConfirmation` | `LMKAlert` |
| `LMKShareService`, `LMKPhotoEXIFService`, `LMKDatePickerHelper`, `LMKOverscrollFooterHelper` | `LMKShare`, `LMKPhotoMetadata`, `LMKDatePicker`, `LMKOverscrollFooterView` |
| `LMKBottomSheetController`, `LMKCardPageController`, `LMKCardPanelController`, `LMKSegmentedPageController` | the same names ending in `ViewController` |
| `LMKEnumSelectionBottomSheet` | `LMKEnumPicker` |
| `LMKToastType`, `LMKBannerType` | `LMKStatus` |
| `LMKChipStyle`, `LMKEmptyStateStyle`, `LMKGradientDirection`, `LMKDividerOrientation`, `LMKTipStyle`, `LMKTipArrowDirection`, `LMKTextFieldState` | `LMKChipView.Variant`, `LMKEmptyStateView.Layout`, `LMKGradientView.Direction`, `LMKDividerView.Orientation`, `LMKTipView.Placement`, `LMKTipView.ArrowDirection`, `LMKValidationState` |
| `LMKGlassView.Style`, `LMKProgressViewController.Style`, `LMKSegmentedControl.CornerStyle`, `LMKActionSheet.ActionStyle` | `.Variant`, `.Mode`, `.Corners`, `Action.Style` (`Style` is reserved for the per-component token structs) |
| `LMKDeviceType`, `LMKScreenSize`, `LMKButtonRole`, `LMKTypographyType`, `LMKShadowConfig` | `LMKDevice.Kind`, `LMKDevice.ScreenSize`, `LMKButton.Role`, `LMKTypography.Kind`, `LMKShadowTheme.Shadow` |
| `LMKPhotoGridContentMode`, `LMKPhotoGridSortOrder` | `LMKPhotoGridViewController.ContentMode`, `.SortOrder` |
| `LMKRequestData`, `LMKResponseData` | `LMKNetworkRequestRecord.Request`, `.Response` |
| `LMK*Strings` types and `lmk*Strings` globals | nested `Type.Strings` with `Type.strings` (process-wide) and an instance `strings` on host-created types |
| `Collection[safe:]`, `String?.nonEmpty`, `NSAttributedString +` | `[lmk_safe:]`, `.lmk_nonEmpty`, `lmk_appending(_:)` |
| `UIControl.lmk_touchAreaEdgeInsets`, `lmk_pointInside` | `lmk_hitTestInsets`, `lmk_point(inside:with:)` (for custom controls; LumiKit controls enforce 44pt themselves) |
| `URLSessionConfiguration.enableNetworkLogging()` | `lmk_enableNetworkLogging()` |
| `LMKFileUtil.generateTempFileURL(fileExtension:)`, `clearTmpDirectory()` | `LMKFile.temporaryURL(extension:)` (non-optional), `clearTemporaryFiles(olderThan:matchingPrefix:)` |

#### Presentation API

- Anything that ends in `host.present(...)` takes `from:`: `LMKAlert`, `LMKErrorHandler`, `LMKActionSheet`, `LMKEnumPicker`, `LMKDatePicker`, `LMKShare`, the photo browser, sheets, and panels. Views installed into a hierarchy use `show(in:)`: toasts, tips, banners, the floating button. Every dismissal is `dismiss()`; every completion closure is `completion:`.
- `LMKToast`: the ten `showSuccess` / `showSuccessOnWindow` entry points collapse into `LMKToast.show(_ status:_ message:duration:in:completion:)`, `show(LMKToast.Configuration)`, `showUndo(message:duration:in:onUndo:onCommit:)`, and `dismissAll(in:)`. With no host the toast presents on the window of the active scene, above presented sheets.
- `LMKBottomSheetViewController.addAsChild(sheet, in:)` and `LMKCardPanelViewController.show(panel, in:)` became the instance method `present(from:)`; `dismissSheet()` became `dismiss(reason:completion:)` and `dismissPanel(completion:)` became `dismiss(completion:)`, both idempotent; `init(cancelTitle:)` became `init(style:)` with the title on `strings`. The sheet's `animateIn()` / `animateOut(velocity:completion:)` and the panel's `animateIn()` are internal: `present(from:)` and `dismiss` drive them. UIKit's `dismiss(animated:completion:)` on a sheet or panel with nothing presented over it runs the component's own dismissal (UIKit would otherwise close the host's modal).
- `LMKActionSheet` is a namespace: build an `LMKActionSheet.Configuration` and call `LMKActionSheet.present(_:from:)`; the class is `LMKActionSheetViewController`. Custom content sizes itself (`contentHeight:` is gone).
- `LMKEnumPicker.present(from:title:options:selection:onSelect:onCancel:)` handles single (`T?`) and multiple (`Set<T>`) selection; `presentMultiSelect` is gone. `LMKEnumSelectable.iconName` is `String?` with a default of `nil`.
- `LMKDatePicker.present(_ configuration:from:onConfirm:)` with `Configuration`, `.past(...)`, and `.future(...)`; `presentRange`, `presentCalendarRange`, and `presentWithTextField` replace the seven presenters, and every form takes an `onCancel`. Under the Mac idiom a wheel picker throws, so `Configuration.resolvedPickerStyle(for:)` maps `.wheels` to `.inline` for date modes and `.compact` for time there; `makePicker(_:)` applies it.
- `LMKAlert.presentTextInput(TextInput, from:onSave:onCancel:)`, `presentActionSheet(actions: [LMKAlert.Action], from:anchor:onCancel:)`, `presentDeleteConfirmation`, `presentCountdownConfirmation`, and `confirm(...) async -> Bool` replace the parameter-heavy forms; `LMKErrorHandler.present(from:)`. `confirm` and `LMKErrorHandler.confirmRetry` resolve `false` when the host cannot present or the alert goes away without an action.
- `LMKFloatingButton` has no global instance: keep the button returned by `show(icon:in:positionKey:onTap:)` and call `dismiss()` on it.
- `LMKShare.present(_ items:from:anchor:completion:)` shares images, files, text, and links in one sheet; `file(at:)` reports its outcome and keeps the file unless `deletesAfterShare: true` is passed (0.x `shareFile` always deleted it; a temporary export that opts in is removed on cancel too).

#### Callbacks

- Closures are named `on<Event>` and carry the new value: `tapHandler` to `onTap`, `actionHandler` to `onAction`, `dismissHandler` to `onDismiss`, `valueChangedHandler` and `stateChangedHandler` to `onValueChange`, `textChangedHandler` to `onTextChange`, `pageChangedHandler` to `onPageChange`, `selectionChangedHandler` and `multiSelectionChangedHandler` to `onSelectionChange` (`Set<Int>`), `backAction` to `onBack`. `LMKButton.didTapHandler` is gone. Two payloads changed with the rename: `LMKTextField` / `LMKTextView.onTextChange` carries `String` (0.x `textChangedHandler` carried `String?`), and `LMKCheckboxCell.onValueChange` carries the new `isDone` (0.x `onToggle` carried nothing). Callbacks are present tense: `on<Event>`, with `onValueChange` for a value, and every presenter that can be cancelled offers `onCancel`.
- Single-method delegates became closures: `LMKSearchBarDelegate` (`onTextChange`, `onSearch`, `onBeginEditing`, `onEndEditing`, `onCancel`), `LMKPhotoCropDelegate` (`onCrop`, `onCancel`), `LMKSharePreviewDelegate` (`onShare`, `onSave`, `onFailure`). The multi-method photo browser and grid data sources and delegates stay.
- `LMKBottomSheetViewController.onDismissTapped()` became `onDismiss: ((DismissReason) -> Void)?` with `cancelButton`, `dimmingTap`, `drag`, `keyCommand`, and `programmatic` reasons.

#### Theme

- The `LMKTheme` protocol, `LMKDefaultTheme`, and `LMKThemeManager` are gone. Colors are an `LMKColorTheme` struct with a fully defaulted initializer; `LMKTheme` is the aggregate value (`colors`, `typography`, `spacing`, `cornerRadius`, `shadow`, `alpha`, `layout`, `animation`, `extensions`) with static `current`, `apply(_:)`, `update(_:)`, `reset()`, `observe(_:)`, and `updates`. An app theme is `extension LMKTheme { static let myApp = LMKTheme(colors: LMKColorTheme(primary: ...)) }`, applied with `LMKTheme.apply(.myApp)`. `configure(colors:typography:...)` and the per-category `apply(spacing:)` are gone.
- Applying a theme re-renders every connected window: `LMKColor.*` are dynamic colors resolved through the `lmkTheme` trait, and components re-apply their styles. Token reads (`LMKSpacing.large`, `LMKColor.primary`, ...) are `nonisolated`, so `static let` defaults and SwiftUI views can read them.
- Color roles: `white` to `onAccent`, `black` to `scrim`, `primaryDark` to `primaryVariant`, `imageBorder` to `outline`, `graySoft` to `fillStrong`, `grayMuted` to `fill`; `photoBrowserBackground` to `LMKPhotoBrowserViewController.Style.backgroundColor`. New roles: `link`, `pressedOverlay`, `selection`, and `highContrastBoost` (applied to accents under Increase Contrast).
- `LMKAlpha` is a seven-step ramp with unchanged values: `overlayLight` to `xxs`, `overlayMedium` to `xs`, `overlayDark` to `small`, `semiTransparent` to `medium`, `overlay` to `large`, `overlayStrong` to `xl`, `overlayOpaque` to `xxl`, `dimmingOverlay` to `dimming`.
- `LMKShadow.small()` / `button()` / `cellCard()` / `card()` / `medium()` / `large()` became `LMKShadow.style(for: .level1 ... .level5)` over `LMKShadowTheme.level1...level5`; `LMKShadow.opacity` became `iconOverlayOpacity`.
- `LMKAnimation.Duration` has seven steps: `buttonPress` to `instant`; `uiShort` and `photoLoad` to `fast`; `actionSheet` and `alert` to `normal`; `modalPresentation`, `listUpdate`, `listInsertDelete`, and `cardExpand` to `moderate`; `screenTransition` and `errorShake` to `slow`; `successFeedback` to `emphasis`. `Spring` and `Curve` are value types on `LMKAnimation`.
- The factories are gone: `LMKButtonFactory.filled(role:title:)` became `LMKButton(title:style: .filled(.role))`, `LMKLabelFactory.caption(text:)` became `UILabel.lmk_make(.caption, text:)`, `LMKCardFactory.cardView()` became `LMKCardView(style: .cell)`. `LMKButton.Style` presets take an `LMKButton.Role`, not a color (`.filled(.destructive)`); `.tint(_:)` sets a custom color.
- The constant bags (`LMKBottomSheetLayout`, `LMKCardPageLayout`, `LMKCardPanelLayout`, `LMKTipLayout`, `LMKFloatingButtonLayout`, `LMKPhotoBrowserConfig`, `LMKBadgeTheme` with `LMKBadge`) and the `open var` appearance getters on the base controllers are `Style` fields now; the `LMKLayout` search-bar metrics live on `LMKSearchBar.Style`.

#### Localization

- Every user-visible default reads from the package's string tables through nested `Strings` structs. Apps that localized LumiKit strings themselves can delete those overrides; apps in other languages override `Type.strings` once at launch or `instance.strings` per view.

#### Removed

| Removed | Use instead |
|---|---|
| `LMKToggleButton` | `LMKButton` with `isToggle = true`, `selectedTitle` / `selectedImage`, `onValueChange` |
| `LMKPhotoGridViewController` as the browser's `LMKPhotoBrowserDataSource` / `LMKPhotoBrowserDelegate` (`numberOfPhotos`, `photo(at:)`, `photoDate(at:)`, and the other display-index members) | An internal bridge serves the browser; ask your own data source (display order follows `sortOrder`) and reach the presented browser through `grid.browser` |
| `LMKKeyboardInsetHelper`; `LMKKeyboardObserver` is internal | `scrollView.lmk_enableKeyboardAdjustment()` / `lmk_disableKeyboardAdjustment()` |
| `UIView.lmk_fadeIn` / `lmk_fadeOut` | `LMKAnimation.fadeIn(_:)` / `fadeOut(_:)` |
| `lmk_safeAreaSnp`, `lmk_setEdgesEqualToSuperview`, `lmk_centerInSuperview`, `lmk_setAutoLayoutSize` | plain SnapKit |
| `UITableView.lmk_configureCellHighlight`, `UIButton.lmk_animatePress` | `cell.lmk_configureCustomHighlight()`, `LMKAnimation.animateButtonPress(_:)` |
| `lmk_configureIconListRow`, `lmk_emptyStateCell` | `cell.lmk_applyListRow(LMKListRowConfiguration(...))`, host the `LMKEmptyStateView` yourself |
| `LMKPhotoEXIFService.extractDate(from: UIImage)` and the other `UIImage` overloads | `LMKPhotoMetadata.read(from:)` on `Data`, a file URL, a `PHPickerResult`, or an `NSItemProvider` (a decoded image has no metadata left to read) |
| `LMKDateFormatterHelper.dateFormatter(...)`, `configure(dateFormat:)` | `LMKDateFormat.string(_:date:time:)`, `LMKDateFormat.preferredDatePattern` |
| `LMKNavigationBar.setLeftItemEnabled(at:)` / `setRightItemEnabled(at:)`, `pinToTop(of:)` | `updateItem(_:_:)` by identifier, `install(in:)` |
| `LMKBottomSheetViewController.containerBottomConstraint`, `refreshSheetColors()` | `additionalBottomInset`, `applyTheme(_:)` |
| `LMKConcurrency.encode` / `decode` returning optionals | the same names throw; `try?` keeps the optional |
| `LMKPhotoBrowserCell`, `LMKCountdownConfirmationViewController`, `LMKNetworkDetailViewController`, `LMKNetworkRequestStore`, `LMKNavigationDirection` | internal |

### Added

#### Theming and styling

- `LMKTheme` with a slot for every component (`theme.button`, `theme.chip`, `theme.navigationBar`, `theme.toast`, `theme.monthCalendar`, `theme.photoBrowser`, `theme.lottieRefreshControl`, and the rest), `LMKThemeExtension` for app-defined values, `LMKThemeApplying` with `lmk_startApplyingTheme()`, and `LMKThemeTrait` (`traitCollection.lmkTheme`, `traitOverrides.lmkTheme`) so a window or subtree can preview a theme without changing the process.
- The style vocabulary: `LMKSurfaceStyle` (`LMKBackgroundStyle` clear / solid / gradient / blur / glass, `LMKCornerStyle` square / fixed / capsule / circle / concentric with masked corners and curve, `LMKBorderStyle` solid / dashed / inset, `LMKShadowSource` level / custom, content insets; the explicit-off values are `.square`, `LMKBorderStyle.hidden`, and `LMKShadowSource.hidden`, because `nil` in an optional style field means "the theme decides") and `LMKControlStateStyle` (highlighted / selected / disabled / focused) on every control; `UIView.lmk_apply(surface:defaults:)` and `lmk_applyCornerStyle(_:)`. Every Style field is optional; `nil` means the theme decides. Every component exposes its structural subviews, `merging(_:)`, and a `didApplyStyle` hook that re-runs on theme and trait changes and always runs last; the open base classes (`LMKButton`, `LMKBottomSheetViewController`, `LMKCardPageViewController`, `LMKCardPanelViewController`, `LMKScrollStackViewController`, `LMKSegmentedPageViewController`, `LMKTabBarController`) call `applyContentTheme(_:)` just before it, the place a subclass styles its own content. Components that play haptics gate them with a `haptics: Bool?` style field.
- Layer colors follow the theme: `lmk_applyShadow(_:)` and `lmk_applyBorder(...)` re-resolve their `CGColor`s on theme, dark mode, and contrast changes.
- Typography: `LMKTextStyle` (`h1` to `h4`, body, caption, and small ladders, `custom(LMKFontSpec)`), `UILabel` / `UITextField` / `UITextView.lmk_apply(_:color:)`, `UILabel.lmk_make(_:text:color:numberOfLines:)`, `LMKTypographyTheme.maximumScale`. Fixed heights became Dynamic Type floors.
- Tokens: `LMKLayout.symbolMicro` through `symbolHero`, `rowHeightCompact` / `rowHeight` / `rowHeightComfortable` / `rowHeightEstimated`, `readableContentMaxWidth`; `LMKColor.onFill(_:preferred:)` and `resolved(_:with:)`; `LMKShadow.Level`; `LMKAnimation.Spring`, `Curve`, and `pressScale`.

#### Controls

- `LMKButton`: `Role` by `Variant` (filled, tinted, outlined, ghost, glass, icon-only) by `Size`, one state machine for highlighted / selected / disabled / focused, `title`, `image`, `setSymbol(_:)`, `isToggle`, `isLoading`, `menu` with `showsMenuIndicator`, `shrinkingTitleToFit(minimumScaleFactor:)`, `minimumHitTarget`, `Style.animatesSymbolChanges` (iOS 26 symbol content transitions), `applyContentTheme(_:)`, and `init(title:style:target:action:)`. `setSymbol(_:)` without a size or weight leaves both to the style; a loading button keeps its current title and absorbs touches.
- New controls: `LMKCheckbox`, `LMKRatingControl`, `LMKCopyableLabel`, `LMKPhotoButton`, `LMKActionTile` (with `UIColor.lmk_glyphTint(onLightAccentDarkenBy:)`).
- `LMKSegmentedControl.Layout` (`equalWidth`, `fitContent`, `scrollable(padding:spacing:)`), `setItems`, `insertSegment` / `removeSegment`, `setEnabled(_:forSegmentAt:)`; a fit-content control scrolls when wider than its host.
- `LMKSlider` ticks and `neutralValue` (iOS 26; ticks appear only when the steps divide the range evenly into at most 50 stops, snapping works regardless), `Style.disabled`, and a localized VoiceOver value; `LMKSwitch` honors `isEnabled` and `setOn(_:animated:)` animates; `LMKTextField` and `LMKTextView` share `LMKTextInputStyle` (with `disabled` and per-`LMKValidationState` overrides), forward every delegate method to the host's delegate (a delegate assigned to the inner `textField` / `textView` becomes that host delegate instead of replacing the wrapper), count `maxCharacterCount` in characters (a paste that overflows is trimmed to fit, never rejected; nothing is cut while an input method composes), and report `onBeginEditing` / `onEndEditing`; the text field owns a kit clear button (`clearButton`, `Strings.clearAccessibilityLabel`) that sends `.editingChanged` and the text-did-change notification as UIKit's does and the text view grows between `minimumHeight` and `maximumHeight`; `LMKSearchBar` gained `cancelButtonMode`, `debounceInterval` with `onDebouncedTextChange` (a pending call is dropped by Cancel, Return, and `text =`), vertical `contentInsets`, and a public `textField`.
- Every LumiKit control answers a 44pt hit area from `point(inside:with:)` while enabled; a disabled control absorbs touches inside its bounds (as UIKit's do) and a hidden one answers none.

#### Components

- `LMKBannerView.show(in:below:insetting:insetsScrollView:)`: a banner shown over a screen sits under the screen's `LMKNavigationBar` (or the safe area), caps its width at the readable width, and adds its height to the top inset of the scroll view below, so content starts under the banner and scrolls beneath it; `isFloating`, and `Style.horizontalMargin`, `verticalMargin`, `maxWidth`, and `dismissSymbolPointSize`. Added to a stack it is part of the layout as before.
- Pointed tips draw the bubble and its arrow as one outline, so `LMKTipView.Style.surface` colors, borders (solid or dashed), and shadows wrap both; `Style.arrowColor` fills the arrow under a gradient, blur, or glass bubble. `LMKToastView.Style.dismissButton` styles a persistent toast's dismiss button.
- `LMKStatus` (success, warning, error, info, neutral) shared by toasts, banners, `LMKStatusLabel`, and validation; `LMKToast.Configuration` (`title`, `action`, seconds or persistent `duration`, `position`, `presentation`, `queuePolicy`), `LMKToast.Handle` (`dismiss`, `setMessage`), and `LMKToast.showUndo` with a countdown ring.
- `LMKSkeletonView` (arbitrary placeholder shapes), `LMKGlassView(variant:)` and `LMKGlassContainerView`, `LMKEmptyStateView.Content` with `asContentUnavailableConfiguration()` and `configure(_:animated:)`, `LMKFilterChipBar.SelectionMode`, `LMKCardView` presets (`cell`, `elevated`, `flat`, `outlined`) and `onTap`, `LMKGradientView` angles and radial gradients, `LMKOverscrollFooterView` that follows its scroll view, `LMKChipView` as a `UIControl` with a distinct selected look, `LMKPageIndicator` hit targets and RTL layout, `LMKTip` with `LMKTipView.Placement` (a VoiceOver modal whose bubble is a container, so the dismiss control is reachable and the escape gesture dismisses).
- Lists: `LMKListRowConfiguration` (a `UIContentConfiguration` with symbol / image / async image leading, title / subtitle / detail, and disclosure / checkmark / switch / badge trailing), `LMKListRowContentView` (with `stateBackgroundView` for the `Style.highlighted` / `selected` looks, driven by the cell's configuration state; a `.toggle` flip is written back into the hosting cell's configuration before `onValueChange`), `lmk_applyListRow(_:)`, `lmk_installRowPointerInteraction(_:)`, `UIListContentConfiguration.lmk_applyTextStyle` / `lmk_applyLeadingSymbol` / `lmk_applyThumbnail`, `LMKListTable.makeInsetGrouped()`.
- `LMKNavigationBar.Style.appearance` (`automatic`, `classic`, `glass`): by default the bar draws the running OS's chrome. On iOS 26 items sit on Liquid Glass, neighbours sharing one capsule and a prominent item taking its own in the tint, the back chevron sits in a circle, and the hairline is gone; before iOS 26 items are tinted glyphs and text over a hairline. `Style.itemGlass` styles the capsules and `itemGlassViews` exposes them.
- Navigation: `LMKNavigationBarItem` with `identifier`, `isEnabled`, `menu`, `badge`, and `role` (plain, prominent, destructive); `updateItem(_:_:)`, `install(in:)`, `subtitle`, `backgroundContentView` (a `UIBackgroundExtensionView` on iOS 26), `pinScrollView(_:edgeEffect:)`; the system-bar bridge `makeBarButtonItem()`, `UINavigationItem.lmk_setItems(leading:trailing:)` (an omitted side is left alone, `[]` clears it), and `lmk_setSubtitle(_:)`; `LMKNavigationController` with `LMKPopGestureConfiguring`: the edge-swipe pop stays available while the system bar is hidden, waits for a transition in flight, and on iOS 26 the content-area pop gesture follows `canBeginPopGesture` too (`updateContentPopGesture()` re-applies it after a push, pop, or a page change in `LMKSegmentedPageViewController`); `childForStatusBarStyle` and `childForStatusBarHidden` answer with the top screen.
- `LMKTabBarController`, `LMKTab` (lazy roots, a `search` role backed by `UISearchTab`; UIKit renders the selected glyph, so there is no `selectedImage`), and `LMKTabBarAppearance`: `selectTab(identifier:)`, `reorderTabs` (a tab filtered out keeps its definition and badge), badges, Command-1 to Command-9 (resting while a modal is up), the iPad sidebar, `applyContentTheme(_:)`, and the iOS 26 minimize behavior and bottom accessory.
- `LMKMenu`: option menus as native `UIMenu`s built from sections (`single` choice, `multiple` toggles that flip in place while the menu stays open, `sort` with a direction, `actions`, `submenu`, `custom`), rebuilt from the host's state each time the menu opens, and anchored from a bar button, a nav bar item, or an `LMKButton` at a compact glyph size (`anchorSymbolConfiguration`).
- `LMKSortMenu`: the sort vocabulary (`Direction`, the tap reduction, `Strings`) and the sort menu on `LMKMenu`, with a live direction arrow, a layout section, and `additionalSections` for filters and commands under the sort.
- `LMKMonthCalendarView` with subclassable `LMKCalendarDayCell` and `LMKCalendarDayDecoration` (dots, badges, glyphs), single / range / multiple selection, interactive paging that respects Reduce Motion, a stateless configure contract (`configure(today: nil)` follows the device's date in its current time zone, whatever time zone the grid's calendar uses, and refreshes at midnight; a passed day is pinned), `Style.headerSurface.contentInsets`, and day numerals in the locale's numbering system; Core `LMKCalendarDay`, `LMKCalendarMonth`, `LMKCalendarSelection` (a reversed `.range` reads in order), and `LMKCalendarSelectionMode`. The day and month types are Gregorian civil dates whatever the supplied calendar: component math runs through `Calendar.lmk_civilCalendar` (a Gregorian twin with the same time zone, locale, and week rules), day and month deltas anchor at noon so a daylight-saving change at midnight cannot shift them, and display uses the supplied calendar only when its months are Gregorian (`Calendar.lmk_hasGregorianMonths`, `lmk_civilDisplayCalendar`).
- Detail cards: `LMKDetailCard` (header, typed rows: key-value, text, chips, photo strip, progress, navigation, link, rating, image, divider, custom; actions; `Progress.value` clamps to `0 ... 1`), `LMKDetailCardView` (`setValue(_:forRowID:)`, `update(rowID:_:)`, `Style.haptics`; a reconfigure restyles rows, chips, and header controls in place), `LMKDetailPageViewController` (cards diffed by id, Edit and Share items that leave the host's leading items alone, `beginEditing` with Command-Return and Escape).
- Containers: `LMKBottomSheetViewController` inner-scroll drags, Escape and Command-W, `contentLayoutGuide`, `resolveStyle(for:)` for subclasses that layer their own sheet style, and a VoiceOver modal (escape gesture, `.screenChanged` on present); `LMKActionSheet.Configuration`, `RowStyle.disabled`, and a public `LMKActionSheetRowView`; `LMKEnumPicker` search and disabled options, sized to its rows; `LMKDatePicker.Configuration`; `LMKCalendarRangeSelectionView.Style` with `theme.calendarRangeSelection` and a `locale`; `LMKCardPageViewController.leadingItem` / `trailingItem` (titled items in a capsule, roles, badges; the back chevron while content is stacked); `LMKCardPanelViewController.presentation` (overlay window or modal) with key-window restore, `Style.heightRatio`, Escape and Command-W, a VoiceOver modal, and `UIViewController.lmk_cardPanel` so a page reaches its panel; `LMKScrollStackViewController` and `LMKFormScaffold` width modes (token insets, readable, capped), `makeFieldRow`, and `makeHeaderStack`; `LMKSegmentedPageViewController.segmentedControlPlacement`; `LMKProgressViewController` terminal states, `observe(_ progress:)`, and Escape; `LMKErrorHandler.policy`.

#### Core and utilities

- `LMKDateFormat` on `Date.FormatStyle`: `Context` (locale, calendar, time zone, hour cycle), `string(_:date:time:)`, `intervalString`, `rangeLabel`, `residenceLabel`, `relativeDayString`, `clockTime`, `dateWithClockTime`, `usesTwelveHourClock`, `widestClockSample`, `monthYearString`, `weekdaySymbols`, cached `formatter(pattern:)`, and `preferredDatePattern` for a user-chosen date format. `LMKFormat` number and percent formatting.
- `LMKLogger`: `minimumLevel`, `isEnabled`, `messagePrivacy`, `entryHandler`, `log(_:_:)`, and the `LMKLogging` protocol with `LMKLogger.default` for injection; messages are autoclosures, built only when a level emits; `LMKLogLevel` is `Comparable`; `LMKLogEntry` is `Codable` and carries `file`, `function`, and `line`; `LMKLogStore` is an O(1) ring buffer whose `formatted()` timestamps are `en_US_POSIX`.
- `LMKURLValidator.validate(_:)` returns `Result<URL, ValidationError>` with the rejection reason; the blocklist adds `0.0.0.0/8`, carrier-grade NAT, multicast, reserved, IPv4-mapped IPv6, and IPv6 multicast, and reads shorthand, octal, and hex IPv4 forms, `*.localhost`, a trailing dot, and bracketed IPv6 literals; `normalizeBaseURL(_:preservingPathExtension:)`.
- `LMKFile.temporaryURL(extension:)`, `clearTemporaryFiles(olderThan:matchingPrefix:)`, and the async `clearTemporaryFilesInBackground(olderThan:matchingPrefix:)` (both return the count; an item whose age cannot be read is kept when an age is given); `LMKConcurrency.encode` / `decode` throw and accept custom coders, `onMainActor` / `onMainActorAfter` return their `Task` (a delay is clamped instead of trapping); `String.lmk_trimmedOrNil`; `LMKDate.calendar` follows time-zone changes from its first read, so `LMKDate.initialize()` is optional and idempotent.
- `LMKImage.downsample(data:maxPixelSize:options:)` and `downsample(fileURL:...)` (sync and async, `prefersHighDynamicRange` through `UIImageReader`), `pixelSize`, `downsampledJPEG`, `imageSize`, `SymbolOptions` (palette / hierarchical / multicolor rendering, variable value, the iOS 26 variable-value and color-rendering modes); `LMKPhotoMetadata` read (`Data`, URL, `PHPickerResult`, `NSItemProvider`) and write (date, coordinate).
- `LMKScene.activeWindowScene`, `keyWindow`, `presentingViewController`, `requestClose(_:onError:)` (the handler runs on the main actor), `configureMacWindow(for:minimumSize:maximumSize:hidesTitleBar:)`, and `observeGeometry(of:onChange:)` (size, safe areas, orientation, the iOS 26 `isInteractivelyResizing` flag); `LMKDevice.observeScreenSize(of:onChange:)`; `LMKDevice.deviceType` no longer traps off the main actor; `LMKTheme.observe(_:)` returns a token that must be kept (releasing it ends the observation).
- `UIViewController.lmk_formKeyCommands(save:cancel:)` with an overridable `lmk_cancelFromKeyCommand()`, `UIView.lmk_pinReadableWidth(in:)` and `lmk_readableWidthGuide`, `lmk_displayScale`, `lmk_forceLayoutDirection(_:)`, `UIScrollView.lmk_disableKeyboardAdjustment()` beside `lmk_enableKeyboardAdjustment()`, the `UISplitViewController.lmk_setInspector(_:)` family, and `lmk_apply(_:animatingDifferences:in:)` for diffable data sources.
- `LMKShare.Item` (image, file, text, url) with `present(_:from:anchor:completion:)` and `text` / `url` conveniences; `LMKHaptics.isEnabled`. `LMKAlert.Strings.countdownConfirmTitleFormat` builds the countdown button title from the string tables.
- `UIColor.lmk_composited(over:alpha:)`: a tint painted over a background as one opaque dynamic color, for tinted surfaces that float over content.
- `UIColor.lmk_stateShade(by:)`: the shade a pressed or selected fill takes, darker by a factor, or lighter when the fill is already dark.
- `LMKLayout.pixelAligned(_:scale:)` and `pixelAligned(_:for:)`: a length rounded to whole pixels of a display, for lines that must render the same thickness on every edge.
- `LMKMenu.reloadVisibleMenu(presenting:)`: rebuilds the open menu from the host's state, for a `.keepsMenuPresented` action in a `custom` section (the toggle and sort sections call it themselves).
- `LMKChipView.Variant.tinted` (`Style.tinted`): a soft wash of the tint with text in the tint, the resting look for chips that toggle.
- `LMKCardPageViewController.Style.showsDragIndicator`, with `dragIndicatorSize` and `dragIndicatorColor`: a grabber at the top of the header for a page in a sheet that a drag down dismisses. The header grows by the room it takes.
- `LMKPhotoBrowserViewController.stageView`: the layer behind the photos, faded on its own by a dismiss drag.

#### Photo, Debug, Lottie

- Photo browser: `Style` with `theme.photoBrowser`, `LMKPageIndicator` and `LMKEmptyStateView` chrome, `LMKButton` overlay buttons, a zoom transition from `zoomSourceView`, HDR through `preferredImageDynamicRange` and the iOS 26 headroom trait, an orientation lock on iOS 26, `onDismiss`, and key commands. Grid: `allowsMultipleSelection` with `selectedIndices` and `onSelectionChange`, `contextMenuProvider`, prefetch hooks (`photoGridPrefetch`, `photoGridCancelPrefetch`), `photoGridThumbnail(at:pixelSize:)` (defaulted: cells ask for a thumbnail sized for the cell and never decode the full image on the main actor), `browser` for the presented browser, a floating glass toolbar the last row scrolls clear of, and the top scroll-edge effect. `LMKSinglePhotoViewer.browser` and `dismiss(completion:)`. Crop: `aspectRatios` and `initialAspectRatio` (`LMKCropAspectRatio` gains 16:9 and 9:16), `onCrop` / `onCancel`, an off-main `UIGraphicsImageRenderer` crop that draws only the crop, hardware-keyboard shortcuts, and a VoiceOver-adjustable crop frame (`Strings.cropFrameAccessibilityLabel` and the move actions). Coordinator: `save(image, metadata) async`, `onPicked`, `onCancel`, `onFailure` (`Failure` is a `LocalizedError` with `hostUnavailable`; failures are logged and, with no handler, shown through `LMKErrorHandler`), `Strings`, `maximumPixelSize`. Share preview: `detents`, `onShare` / `onSave` / `onFailure` / `onDismiss`, `isSaving`; the Save Image button shows only when `NSPhotoLibraryAddUsageDescription` is declared unless `Style.showsSaveButton` says otherwise. `LMKPhotoMetadata.write` copies the encoded pixels through untouched (every frame and gain map) and stamps the EXIF dates with their offset and subseconds; `read` honors them.
- Photo gestures. Grid: a pinch steps the column count while the photo under the fingers stays under them, the grid leans into the pinch between steps (`Style.pinchFeedback`), and scrolling waits for the fingers to lift; while selecting, a sideways drag selects or deselects every photo between its first cell and the finger and scrolls the grid near its edges; a touch dims the photo (`Style.pressedAlpha`). Browser: a double tap zooms on the tapped point of the photo; a zoomed photo pans to its edges and a drag past the left or right edge pages; a long press anywhere on the page plays a Live Photo; the Mac's trackpad pinch zooms around the pointer.
- Debug: `LMKNetworkLogger.Configuration` with credential redaction on by default (`Authorization`, `Cookie`, `Set-Cookie`, `X-API-Key`, `api-key`, `x-goog-api-key`, `x-access-token`, `x-amz-security-token`, `x-csrf-token`, `x-xsrf-token`, `ocp-apim-subscription-key`, `x-functions-key`, plus `redactedQueryItems` for `key`, `token`, `signature`, and the other credential query items, applied to the URL, a `Location` header, and a URL password), `hostFilter`, body caps, and `recordsDidChangeNotification`; `redact(_ url:configuration:)` and `record(id:)`; request bodies are captured (`Request.isBodyTruncated` / `Response.isBodyTruncated` say when the cap cut them) and redirects are reported to the app's session, which decides whether to follow; the inner session is one shared `.default` session (the app's cookie jar, cache, and credential storage keep working while logging is on); a diffable `LMKNetworkHistoryViewController` on list rows with an empty state and a localized detail screen; copied payloads expire from the pasteboard. The whole product compiles only under `LMK_ENABLE_NETWORK_LOGGING`.
- Lottie: the bundled ring tinted from `theme.lottieRefreshControl`, `Style` (`pullThreshold`, `timeline`, `minimumSpinDuration`, `size`, tint), `Timeline(animation:)` (an injected animation plays its own timeline, split at a `PHASE2_SPIN_LOOP` marker or looped whole), `install(on:style:onRefresh:)` (returns `nil` under the Mac idiom), `makeRefreshKeyCommand(action:)` for Command-R; the ring re-tints on appearance and contrast changes and follows Reduce Motion at runtime.

#### Platform

- iOS 26 APIs behind `#available` with same-API fallbacks: Liquid Glass surfaces and glass buttons, container-concentric corners, scroll-edge effects, tab bar minimize behavior and bottom accessory, `UISearchTab`, navigation subtitles, prominent bar items with badges and transition identifiers, slider ticks and neutral value, symbol content transitions, symbol variable-value and color-rendering modes, the split view inspector column, HDR headroom, the natural-alignment trait for RTL, interactive-resize geometry, orientation lock, and background extension views. The full table and the iOS 27 follow-ups are in [docs/PLATFORM.md](docs/PLATFORM.md).
- Mac Catalyst: the Example app builds for the Mac idiom; `UISlider` tints are gated (they throw under the idiom); a wheel `UIDatePicker` throws too, so `LMKDatePicker` resolves `.wheels` to `.inline` or `.compact` there; the Lottie refresh control returns `nil` under the idiom and offers a Command-R key command instead.

#### Infrastructure

- GitHub Actions CI (lint, iOS tests under Xcode 26 and Xcode 27, Catalyst build, native macOS build of Core and Debug, the Example built for iOS and Mac Catalyst with its tracked project checked against `xcodegen generate`, DocC archives) and `make build` / `build-catalyst` / `build-host` / `test` / `test-filter` / `example` / `example-catalyst` / `docs` / `migrate` / `clean`; warnings are errors under `LUMIKIT_WARNINGS_AS_ERRORS`. SwiftLint keeps components off `LMKTheme.current` and off the global token proxies (`no_theme_store_in_components`, `no_global_token_proxies_in_components`).
- DocC catalogs for the five products; CONTRIBUTING.md, SECURITY.md, docs/MIGRATION-1.0.md, docs/PLATFORM.md; `.spi.yml` builds the Foundation-only products natively on macOS for the Swift Package Index.
- `Scripts/migrate-1.0.sh` with `migrate-1.0.rules`: renames, dotted paths, call shapes, members, and a report of the hand edits by file and line; `--dry-run` reports over a rewritten mirror, a dirty consumer tree is refused without `--allow-dirty`, and the package's own tree is never rewritten.
- Example app: 68 pages in 12 sections that follow what a developer comes looking for (one source file per page, in a folder per section), a search field over the catalog, a theme switcher, and a scripted accessibility sweep (`-lmk-audit-all -lmk-config <name> -lmk-screenshots <dir>`, plus `-lmk-rtl` and `-lmk-theme`) that checks truncation, clipping, overlap, 44pt targets, labels, WCAG contrast, and fixed fonts on every page. `-lmk-live-photo <still> <video>` opens a Live Photo from two files on a simulator whose library has none.

### Changed

- `LMKDevice.ScreenSize` tiers by portrait width and size class, never `UIScreen`: regular width and regular height is `.extraLarge`; otherwise up to 375pt `.compact`, up to 402pt `.regular`, wider `.large`. `LMKSpacing.cardPadding` and `cellPaddingVertical` tier regular-by-regular windows by the shortest side (up to 768 compact, up to 834 regular, wider large). `LMKScene.screenScale` and `LMKLayout.hairline` read the display-scale trait; `lmk_windowOrientation` reads `effectiveGeometry`; `LMKBottomSheetViewController` derives its slide-out offset from the window.
- `LMKGlassView` renders Liquid Glass on iOS 26 and a system-material blur before; `lmk_applyConcentricCorners` and `LMKNavigationBar.attachScrollEdgeEffect(to:)` adopt the iOS 26 APIs with fallbacks.
- List rows wrap titles and subtitles by default (`Style(titleLines: 1, subtitleLines: 1)` keeps a single-line row). A row is as tall as its content plus `Style.contentInsets`' top and bottom, never shorter than `minimumHeight`.
- `LMKNavigationBar` follows the OS by default (`Style.appearance`); `theme.navigationBar.appearance = .classic` keeps tinted items over a hairline on every OS.
- Detail cards carry a hairline `outline` border and the `level1` shadow by default, in place of the `level3` shadow alone. `LMKDetailCardView.Style.card` overrides both.
- `LMKMonthCalendarView.Style.dayRowHeight` is a floor: rows grow to hold the numeral and the tallest decoration band the decorations use, and one row height serves every month they cover.
- The photo grid hides the iOS 26 bottom scroll-edge effect by default, so photos run to the edge under the floating toolbar (`Style.showsBottomEdgeEffect` brings the band back); `showsScrollEdgeEffects` governs the top effect.
- The photo browser asks `photoLivePhoto(at:)` for every page; `photoIsLivePhoto(at:)` only shows the badge before the load lands.
- `LMKBannerView` draws an opaque tinted surface with a hairline border in the status color, `medium` corners, and a compact dismiss glyph, one touch target tall.
- `LMKPageIndicator.Strings` gains `accessibilityLabel` as its first parameter.
- `LMKLogEntry.message` is the raw message; the call site lives in `file`, `function`, and `line`, and `formattedMessage` joins them. The store's `formatted()` output is unchanged.
- `LMKChipView`'s selected state is a distinct appearance (a filled tint by default) rather than an inverted variant; `LMKColorTheme.primaryVariant` defaults to a slightly darker primary. A chip filled in both states shades its fill by a quarter when selected.
- A pressed chip changes its fill (a filled chip shades it, a tinted or outlined one takes a wash of the tint) in place of dimming the whole chip; `Style.highlighted` still overrides.
- `LMKFilterChipBar` with a filled chip style draws the chips that are not selected in the soft tint and the selected one in the full tint. Setting `selectedVariant` or `selected` on the chip style keeps both looks as given.
- Photo view controllers present full screen by default. The photo browser presents over the full screen (`.overFullScreen`), so the screen it came from stays underneath and shows through during a dismiss drag; a host that sets `.fullScreen` gets the same motion over black.
- Photo browser dismiss drag: the photo follows the finger a full page up or down, only the stage fades (to `Style.dismissMinimumAlpha`, now 0.1, at the threshold), and a drag let go short of the threshold coasts back.
- Photo browser zoom: with a `zoomSourceView` the browser runs its own transition in place of the iOS 18 zoom transition. Only the photo travels between its thumbnail and the stage while the stage fades; the screen underneath no longer scales down and back. A dismissal starts from wherever a drag left the photo, and fades when the thumbnail is off screen.
- Capsule and circle corners (`LMKCornerStyle.capsule`, `.circle`, `lmk_makeCircular()`) are drawn with `layer.cornerRadius` on every OS and follow the view's size on their own; they no longer publish iOS 26's `UICornerConfiguration.capsule()`. `asConcentricContainer` does not publish a view that clips and already has a border.
- Border widths (`lmk_applyBorder`, `LMKBorderStyle`, outlined buttons, tip outlines) round to whole pixels of the view's display: a 1.5pt border is 5 pixels at 3x and 3 pixels at 2x.
- `LMKBadgeView` hugs its content on both axes: a stack never stretches or squeezes it.
- `LMKButton.isLoading` keeps the current title (an icon-only button does not widen) and absorbs touches instead of turning interaction off; VoiceOver reads the button as not enabled. A surface fill on a button is its resting look and the states shade it like a filled button; a translucent border keeps its own alpha.
- `LMKSwitch.Style.thumbTint` defaults to `LMKColor.onAccent`.
- `LMKCardView.contentView` is clear and clips to the card's concentric curve, so edge-to-edge content follows the corners; a tappable card names itself to VoiceOver from its content unless the host labels it.
- `LMKFilterChipBar.Style.chip` layers over `.outlined`: a partial chip style (a tint alone) keeps the outlined default, and an explicit `.filled` is still softened.
- `LMKLoadingStateView` starts hidden and shows from `startLoading()`; its inline layout sizes to the indicator and message.
- `LMKGradientView` no longer hides a host's subviews from accessibility.
- `LMKTipView.Style.minMargin` clamps against the safe area, not the host's edges; `.automatic` placement measures the bubble against the room on both sides; the dismiss area reads as "Got it, button" with the tap-anywhere hint.
- Toasts: `.inWindowScene` hosts on the window itself, above presented sheets. A toast that never shows (no host, dropped from the queue, `.dropIfBusy`) reports `onDismiss(.programmatic)`; a queued toast displaced by `.replace` reports `.replaced`. A toast whose host leaves the window (its screen went away) dismisses with `.programmatic`, so an undo toast commits and a persistent toast never keeps its controller alive. `LMKToast.Configuration.haptics` is the haptics switch.
- `LMKProgressViewController.present(from:)` is skipped with a logged warning when the host is already presenting; `dismiss(completion:)` during the presentation waits for it to land.
- `LMKShadowSource.hidden`, `lmk_applyShadow(.none)`, and a zero-opacity `LMKShadowStyle` clear the shadow instead of registering an invisible one; only a visible shadow sets `masksToBounds = false`.
- `LMKColorTheme.primaryVariant`, `link`, `outline`, and `selection` derive from the current `primary` and `divider` until set; `highContrastBoost` is clamped to `0 ... 1`.
- `UIColor(lmk_hex:)` rejects a string with a non-hex character instead of parsing a valid prefix.
- Small informational text meets WCAG AA by default: the `.small` text style, text field and text view helper lines and counters, detail card row descriptions, and the month calendar's weekday symbols default to `LMKColor.textSecondary` instead of `textTertiary` (placeholders, clear buttons, and decorative icons stay tertiary, as in UIKit).
- A label styled with line metrics (`UILabel.lmk_make`) aligns `.natural` text to the view's layout direction like a plain label, instead of by the text's own direction, and follows a layout direction change.
- Under the Mac idiom `LMKButton` and the chip's dismiss button keep their iOS look (`preferredBehavioralStyle = .pad`) instead of drawing as bare titles; a window-scene toast lands on the window of the controller on top, so it shows over a Mac page sheet; `LMKSkeletonView` shapes default to `LMKColor.fill`, visible on a light background.
- `LMKCornerStyle.concentric(minimum:corners:curve:)` keeps its curve and honors masked corners on iOS 26.
- `LMKNetworkRequestRecord.displayDuration` is locale-formatted ("2,500ms"); the inspector's detail text is localized.
- `LMKMarkdownRenderer.render` and `renderFull` are callable from any isolation (`makeInlineTextView` stays on the main actor); `LMKImage.dominantColor` / `dominantColors` and `LMKDevice.deviceType` too.

### Fixed

- `lmk_touchAreaEdgeInsets` did nothing unless the owner overrode `point(inside:with:)`, so every hit-area expansion set from an app was inert; LumiKit controls now enforce the minimum target themselves.
- `LMKSwitch`, `LMKSegmentedControl`, and `LMKChipView` ignored `isEnabled`.
- A tap on a chip's title or icon did nothing (only the padding around them answered), which made every `LMKFilterChipBar` hard to use; the chip now answers hit tests itself. A badge on `LMKFloatingButton` swallowed touches the same way.
- `LMKTextField` and `LMKTextView` helper text wrapped one word per line when the field was first laid out narrower than its final width.
- Count badges on a month calendar spilled into the next week, and the last week's were clipped at the grid's edge.
- A persistent toast's dismiss button stretched across the toast.
- `LMKLottieRefreshControl` showed a still ring while loading when UIKit started the refresh mid-drag.
- Photo browser: a zoomed photo could be panned off the page into the empty stage, a double tap zoomed on a point other than the tapped one, the chrome stayed hidden after paging away from a zoomed photo, and a Live Photo never loaded unless the data source also implemented `photoIsLivePhoto(at:)`.
- Photo browser: a dismiss drag faded the photo together with the stage and showed black behind both; letting go snapped the stage back to opaque before the photo zoomed out; a swipe made in the first second after the browser opened was sent back to the first photo when the presentation finished; a later appearance (a sheet over the browser went away) returned to the initial photo; at 1x a photo narrower than the page took the first sideways drag from the paging; the LIVE badge stayed while the rest of the chrome cleared.
- A pressed or selected neutral filled button turned black: the state shaded the label color in place of the gray fill.
- A badge on an `LMKNavigationBar` item was cut at the top by a host that clips the bar.
- A banner shown over a screen covered the content under it and let that content show through.
- The selected row of `LMKSortMenu` flipped its direction only once while the menu stayed open.
- `LMKMenu` toggles and the re-tapped sort row changed the host's state without repainting the open menu: the checkmark and the direction arrow stayed as they were until the menu was reopened. The open menu is now rebuilt after every row that keeps it open.
- On iOS 26 and later a border thinned around rounded corners wherever a view published a corner configuration, clipped, and had subviews: outlined chips lost a quarter of their border on the ends, and a hairline around a capsule search bar all but disappeared there. A border whose width was a fraction of a pixel (the 1.5pt chip outline at 3x) also rendered thicker on some edges than on others.
- `LMKNavigationBar.pinToTop(of:)` ignored its argument.
- `LMKDeviceHelper.deviceType` trapped when read off the main actor.
- `LMKShadowStyle` had no public initializer.
- `LMKPhotoEXIFService.extractDate(from: UIImage)` re-encoded a decoded image to look for metadata that was already gone.
- `LMKLogger` category globals were an unsynchronized data race.
- The overlay-window card panel stole key-window status and leaked its window.
- The photo grid's sort and content-mode buttons showed no image.
- Found by the accessibility sweep: `LMKMonthCalendarView()` recursed until stack overflow; `LMKListRowContentView` returned an unbounded fitting height inside tables; brightness adjustments were misused at four sites, so selected chips, pressed buttons, and every accent under dark mode with Increase Contrast rendered near black; `UISlider` tints threw under the Mac idiom; fit-content segmented controls collapsed a segment at large text sizes; detail card headers, checkbox cells, and list rows truncated at accessibility sizes; sliders, search fields, link rows, and copyable labels had hit areas under 44pt; page indicators, list-row switches, and chip dismiss buttons had no accessibility label.
- `LMKDevice.hasTopNotch` was `true` on every iPad; `LMKFloatingButton` could be dragged under a side safe-area inset; the card panel ignored safe areas; `LMKSegmentedPageViewController` installed its first page at zero width; `LMKLoadingStateView` broke a constraint as a table background view.
- `lmk_topViewController` recursed forever on an empty navigation or tab controller; `lmk_presentAlertOnTop` replaced a popover's valid anchor.
- `UIScrollView.lmk_enableKeyboardAdjustment()` scrolled a text view that was the scroll view itself toward its own bounds, and added the keyboard overlap on top of what UIKit already insets below the content.
- `LMKMarkdownRenderer` styled headings by line index, so a heading moved when the inline parser changed the line count, and never detected tables in CRLF input.
- `LMKAnimation.animateErrorShake` under Reduce Motion erased the view's border; the error flash is now its own layer.
- A reused cell's custom highlight lost its overlay when a stale un-highlight completion landed after the next highlight.
- Network logger: request bodies were never captured; redirects were followed silently inside the logger's own session instead of by the app's; the `.ephemeral` inner session dropped the app's cookies, cache, and credentials while logging was on; a disabled logger still intercepted requests on a session that listed it; `x-goog-api-key`, `api-key`, and credential query items went through unredacted.
- `LMKDate.calendar` followed a time-zone change only after `initialize()` had been called.
- Relative day strings and calendar day and month deltas were off by one in zones where daylight-saving time starts at midnight.
- `LMKURLValidator` let shorthand, octal, and hex IPv4 forms (`0177.0.0.1`) and `*.localhost` hosts through.
- `LMKLottieRefreshControl` kept a refresh armed after the pull dropped back below the threshold, armed on bounces and programmatic offsets, and wrote to the animation view on every scroll tick while at rest.
- `LMKCheckboxCell` flipped its checkbox while the row's `isDone` stayed put, and a VoiceOver double tap toggled a row whose checkbox was disabled (the row now reads as not enabled).
- `LMKTextField` and `LMKTextView` counted the character limit in UTF-16 units, cut text while an input method was composing, and rejected a paste that overflowed; the field's clear button never showed because a trailing spacer defeated `clearButtonMode`.
- `LMKSegmentedControl` began its indicator drag on any pan, including vertical scrolls, and dropped taps in the hit band and the inset ring; `LMKSwitch.setOn(_:animated:)` never animated.
- `LMKRatingControl` rebuilt its glyphs without their configuration when `maximum` changed, cleared on a retap with no jitter tolerance, and mapped a drag past the edge to the wrong end in RTL.
- `LMKSegmentedPageViewController` left the control ahead of the page when a page change was rejected, recognized its pan together with the control's indicator drag and sliders, and ignored `setPages` / `setPage` before the view loaded.
- Bottom sheets: a tall sheet lifted by the keyboard was pushed above the top safe area; a sheet presented over an open keyboard sat behind it; a dismissed sheet could not be presented again; `presentRange`'s pickers were retained forever; rows in an action sheet were tappable during a page slide; the enum picker had a fixed row height.
- `LMKNavigationBar` ignored the left and right safe-area insets; a replaced item set leaked size constraints.
- Tips: a pointed tip was re-dimmed by the next theme pass, froze its source frame across a resize, and `dismiss()` could fire twice. Banners: a dismissed banner came back invisible. Floating buttons: the button was never re-placed when its superview resized, and `positionKey` set after `show` did not move it. Chips: a display-only chip swallowed touches meant for the view behind it. Empty states: content insets were ignored as soon as the message wrapped. Card pages: header items only worked as glyphs; `title` set after load did not update the header. Card panels: a panel dismissed by UIKit kept `isPresented == true`, and the pass-through overlay dropped touches meant for a controller the panel presented. Filter chip bars: vertical insets clipped the chips, and an overflowing bar opened on its last chips in RTL. Page indicators: counts were never clamped. Skeletons: the shimmer did not come back after the app returned to the foreground and its colors ignored dark mode.
- A pointed tip stretched or moved its source view to center the bubble over it whenever only content hugging held the source's width (a chip in a row with a spacer). The bubble now anchors to the source's frame, read each time the tip lays out, and never constrains the source.
- `LMKSearchBar`, `LMKRatingControl`, a floating `LMKBannerView`, and the overlay buttons of the photo browser, crop editor, and share preview logged unsatisfiable-constraint warnings: the search bar laid itself out at zero size from `init`, the rating control solved its glyph row against a zero-width frame before its first layout, the banner's width cap started at zero, and the overlay buttons were pinned to a zero size against their own minimum height.
- Content sat under a floating sidebar. An iOS 26 tab bar or split view sidebar (iPad and Mac) reports itself as a leading safe area of the content beside it, and `LMKScrollStackViewController`, `LMKFormScaffold`, and `lmk_pinReadableWidth` / `lmk_readableWidthGuide` measured their sides from the raw edges. They now measure from the safe area, which also keeps content clear of the sensor housing in landscape; the scroll view and its background stay full-bleed.
- `LMKCardPageViewController` drew its header items under the status bar, or under the window controls on a Mac, when the page filled the screen (a card page pushed with the system bar hidden, such as `LMKNetworkHistoryViewController`). The header's surface stays full-bleed and its content sits inside the safe area.
- Under the Mac idiom, dismissing a full-screen presentation left the window toolbar without the back button of the `LMKNavigationController` underneath; the controller now restores it.
- `LMKEmptyStateView`'s stacked layouts took their width from the message, so a view laid out at zero size first (a table background) kept a one-word-per-line message. The text column now fills the view's width.
- Photo browser: a rotation or resize left the pages misaligned and at the old size; a one-finger drag at 1x fought the paging on a trackpad; a dismissal that started during the zoom-in left the thumbnail invisible; a pinch released past the maximum reported the page as not zoomed; in RTL the pages and arrow keys ran the wrong way. Grid: every cell decoded and held the full-size image; the hand math mirrored the columns wrongly in RTL. Crop editor: the crop rendered a full-size bitmap first, lost a locked ratio when the crop area shrank under the frame, and took its pinch only outside the frame. Pick-and-crop: a cancel during the load did not stop it, and the crop editor could be presented before the picker had gone. Share preview: a second Save tap during a save wrote twice, and a save in a host without `NSPhotoLibraryAddUsageDescription` went to the photo library anyway instead of reporting `.photoLibraryAccessDenied`.
- `LMKAlert.presentCountdownConfirmation`: a long message pushed the card off screen (the text scrolls inside the card now); the countdown title was built in code rather than from the string tables.
- Day cells rendered "21日" instead of "21" in Chinese and Japanese locales.

### Deferred

Codable themes, a `LumiKitSwiftUI` product, video in the photo browser, and the iOS 27 APIs (listed in [docs/PLATFORM.md](docs/PLATFORM.md)) are 1.x work.

## [0.12.0] - 2026-08-04

### Changed

- **BREAKING: `LMKPhotoGridDataSource.photoGridImage(at:)` is now async** — `func photoGridImage(at index: Int) -> UIImage?` → `func photoGridImage(at index: Int) async -> UIImage?`, so providers can decode images off the main actor instead of being forced into synchronous loads. Migration: add `async` to the implementation. A source holding decoded images returns them unchanged; a disk- or network-backed source should decode off the main actor and return a ready-to-display image. Grid cells show a neutral placeholder while an image loads, and a slow result never lands on the wrong cell. Sort, pinch-to-zoom columns, content-mode toggle, and Live Photo badges are unchanged.
- **BREAKING: `LMKPhotoBrowserDataSource.photo(at:)` is now async** — same shape and migration as the grid method. Browser pages show a placeholder while loading; zoom, delete, and Live Photo playback behave as before. `LMKSinglePhotoViewer` conforms by returning its in-memory image immediately.
- **SnapKit 6** — Dependency floor raised from 5.7.0 to 6.0.0. SnapKit 6's breaking changes are packaging-only (CocoaPods/Carthage removal, platform floors, Swift 6 toolchain); no source changes are needed at this package's iOS 18 floor.
- **`UIView.lmk_applyBorder` hairline default** — The `width` parameter now defaults to `LMKLayout.hairline` (one physical pixel at the current screen scale) instead of 1pt. Callers passing an explicit width are unaffected.

### Added

- **LMKEmptyStateView action button** — `configure(message:icon:style:action:)` gains an optional `Action` (title, optional leading SF Symbol, `LMKButton.Style`, tap handler), rendered as a button below the message in the `.fullScreen` and `.card` styles; the horizontal `.inline` style ignores it. `setAction(_:)` adds, replaces, or removes the button after configure. The view sizes itself to its content, so a long message at a large Dynamic Type size can never overlap the button; hosts should pass an `Action` instead of anchoring their own button to the view's bottom edge. With an action present, VoiceOver exposes the message and button as separate elements.
- **LMKBottomSheetController.avoidsKeyboard** — Default `true`: the sheet lifts by the keyboard's actual overlap (floating keyboards and reduced-size windows lift only as much as they are covered), animates with the keyboard, and restores on hide; drag-to-dismiss still works while lifted. While enabled, the controller owns the keyboard offset: subclasses with hand-rolled keyboard observers should delete them, or return `false` for fully manual control. `LMKKeyboardObserver.KeyboardInfo` gains a `frameEnd` rect.
- **LMKScrollStackViewController navigation bar + keyboard hooks** — Overridable `navigationBar: LMKNavigationBar?` (default nil) pins a custom bar with the scroll view starting below it, and `installsKeyboardAdjustment` (default `true`) enables keyboard avoidance on the scroll view out of the box. Existing subclasses keep identical layout with both defaults.
- **LMKFormScaffold** — Static builders for form screens that are not `LMKScrollStackViewController` subclasses: `makeScrollView(keyboardDismissMode:)` (keyboard avoidance pre-installed), `makeContentStack(spacing:)`, and `install(scrollView:stack:in:below:contentInsets:)` pinning the pair into a host view below an optional top anchor with design-token insets.
- **LMKSegmentedPageController.pageContainerView** — Overridable container view for the paged content (default: the controller's own view), letting subclasses confine pages to a sub-region, for example below a fixed header.
- **LMKPointerStyle** — Window-safe `UIPointerStyle` factories for `UIPointerInteractionDelegate`: `automatic(for:)`, `highlight(for:)`, `lift(for:)`, and `hover(for:preferredTintMode:prefersShadow:prefersScaledContent:)`. Each returns `nil` unless the view is non-nil and attached to a window, so the result can be returned straight from the delegate. Use these instead of constructing `UITargetedPreview(view:)` directly, which crashes when the view has left its window (a cell recycled or a sheet dismissed mid-hover).
- **Icon list row pointer hover** — `lmk_configureIconListRow` gains `pointerEnabled: Bool = true`, giving the row pointer hover feedback on iPad and Mac Catalyst. Inert on platforms without pointer support.
- **LMKLayout.hairline** — One physical pixel at the current screen scale, with `hairline(forScale:)` for an explicit scale. Deliberately not a theme axis: display physics, not branding.

### Fixed

- **Keyboard avoidance leaving the focused field covered** — `UIScrollView.lmk_enableKeyboardAdjustment()` (added in 0.11.0) could fail to bring the focused field above the keyboard, including when focus moved between fields or the layout resized while the keyboard stayed up. Fields now reliably scroll into view.
- **Bottom sheet invisible in container controllers** — A sheet added via `LMKBottomSheetController.addAsChild` to a container such as `UINavigationController` never animated in: it sat invisible while its clear dimming view blocked touches. The sheet now appears regardless of the host.
- **LMKPhotoBrowserCell pointer crash** — Hovering a photo cell on iPad or Mac Catalyst while it left the view hierarchy could crash the app. The cell now routes its pointer style through `LMKPointerStyle`.
- **LMKEmptyStateView zero-height collapse** — With no host-imposed height the view collapsed to zero and its content spilled over neighboring views (most visibly in stack layouts). The view now takes its content height when the host imposes none; a host-imposed height still wins and centers the content.
- **LMKEmptyStateView Dynamic Type reflow** — A mid-session text-size change now reflows the message immediately instead of waiting for the next `configure()` call.
- **LMKActionSheet subtitle crush in tall sheets** — When enough rows pushed the sheet past its max-height cap, the scroll view's content-hugging constraint tied with the labels' vertical compression resistance (both priority 750) and the solver squashed every title and subtitle toward zero height instead of scrolling. The hug constraint now sits below label compression resistance, so overflowing sheets scroll and rows keep their content height.

### Infrastructure

- 1008 → 1073 tests (147 suites); 120 → 122 source files.
- Example app: the photo grid and browser pages demonstrate the async image data sources, and the catalog showcases the other new APIs.

## [0.11.0] - 2026-07-26

### Added

- **UIScrollView.lmk_enableKeyboardAdjustment()** — One-call keyboard avoidance: the scroll view keeps the focused input visible above the keyboard, tracks keyboard frame changes, and restores its insets on hide. Safe to call multiple times; no-op on Mac Catalyst. `LMKKeyboardInsetHelper` remains supported where explicit start/stop control is wanted.
- **Pointer hover feedback** — `LMKButton` and `LMKNavigationBar`'s bar buttons (back button, left and right items) respond to the pointer on iPad and Mac Catalyst.
- **LMKFilterChipBar icons** — `configure(allTitle:filterTitles:filterIcons:style:)` accepts optional leading icons, positionally matched to `filterTitles`. `nil` or missing entries render text-only chips, and the "All" chip never carries an icon. Source-compatible with the existing `configure`.
- **LMKPhotoBrowserViewController.showsActionButton** — Opt-out for the overlay "…" action button (default `true`, set before presenting), for hosts whose current user has no actions to offer, such as read-only shared content. `LMKSinglePhotoViewer` hides the button automatically when its `onAction` callback is nil, and `LMKPhotoGridViewController` forwards a new `browserShowsActionButton` to the browsers it presents.
- **LMKPhotoBrowserViewController.actionButtonSystemImageName** — Configurable SF Symbol for the action button (default `"ellipsis"`, set before presenting), so a host whose sole action is destructive can read as such (e.g. `"trash"`). `LMKSinglePhotoViewer` forwards it via a new `actionIconSystemName` init parameter.

### Changed

- **LMKPhotoPickCropCoordinator optional crop** — New `croppingEnabled` init parameter (default `true`, source-compatible). Passing `false` skips the square-crop editor and stores the picked image as-is, for content whose full frame matters (receipts, documents).
- **LMKAnimationHelper press animation accepts any UIControl** — `animateButtonPressDown` / `animateButtonPressUp` / `animateButtonPress` widened from `UIButton` to `UIControl` (source-compatible), so custom controls such as tiles and photo buttons can reuse the press animation. Scale, alpha, and Reduce Motion behavior unchanged.

### Fixed

- **LMKBottomSheetController drag with the keyboard up** — Starting a drag on a sheet held above the keyboard no longer snaps the sheet down by the keyboard's height while the keyboard stays up covering it. The drag now dismisses the keyboard first.
- **LMKBottomSheetController in embedded hosts** — A sheet presented in a view smaller than the screen (child-VC embedding, form sheets, resizable Mac Catalyst windows) no longer lets tall content push its drag indicator and back button outside the hosting view, where they were visible but could not be tapped. Sheet height is now capped against the host rather than the screen.
- **LMKNavigationBar inline title with four or more right items** — Bar buttons keep their 44pt touch targets instead of being squeezed below them; the inline title now shifts or truncates to make room.
- **LMKSwitch stretched by stack views** — The switch holds its intrinsic size inside a stack view (`UISwitch` parity) instead of being stretched or squeezed, letting neighboring labels absorb the slack.
- **LMKPhotoBrowserViewController overlay noise** — The date/subtitle pill is hidden when the current photo has neither a date nor a subtitle, and a single-photo browser no longer shows a "1 of 1" counter or a one-dot page control.

### Infrastructure

- 992 → 1008 tests; 119 → 120 source files.

## [0.10.0] - 2026-07-15

### Added

- **LMKSegmentedPageController** — Base class for a segmented tab container that pages between child view controllers with an interactive finger-tracking pan. Subclasses override `makePages()`, `usesFullWidthSwipe(forPageAt:)` (full-width vs edge-only pan, for pages that own interior horizontal drags), and `didChangePage(to:)`; `setPage(_:animated:)` slides for taps and deep links. The top `LMKSegmentedControl` is installed via the overridable `installSegmentedControl()` (default: nav title view).
- **LMKCheckboxCell** — Check-off row for to-dos and checklists: checkbox + strike-through title, `configure(title:isDone:)`, `onToggle` callback. The checkbox hit area expands to the minimum touch target; done state is exposed via `accessibilityValue` and the `.selected` trait.
- **LMKPhotoPickCropCoordinator** — Pick → square-crop → store flow for a single photo using a permission-free `PHPicker`. Storage is injected as a `(UIImage) -> String?` closure; the host retains the coordinator for the flow's duration.
- **LMKSinglePhotoViewer** — One-image data source + delegate adapter for `LMKPhotoBrowserViewController`, with optional subtitle and action-button callback.
- **LMKFilterChipBar multi-select** — `allowsMultipleSelection` adds an additive mode where taps toggle chips independently (no radio behavior). Selection is reported through `multiSelectionChangedHandler` as a `Set<Int>` of filter indices and readable via `selectedIndices`, with a silent `setSelectedIndices(_:)` for programmatic state. Deselecting the last chip is allowed and reports an empty set (consumers decide how to render it, typically as "show all"); the "All" chip, when configured, clears the set and stays highlighted while the selection is empty. The single-select API is unchanged.
- **LMKAlertPresenter.presentTextInput** — Single-text-field alert with save/cancel for name, title, and identifier prompts. The save action hands back the field's text verbatim; trimming and empty checks stay with the caller. `Strings` gains a configurable `save` title. An optional `configureField` closure covers anything the standard parameters don't (secure entry, content padding, delegates); it runs after the standard configuration is applied, so its changes win.
- **LMKDatePickerHelper.presentCalendarRangePicker** — Single-calendar range selection built on `UICalendarView` multi-date selection: the first tap sets the start, a later tap sets the end, an earlier tap re-anchors, and any tap once a full range exists begins a new selection. `onConfirm` fires only when something is selected.
- **LMKMarkdownRenderer code & tables** — `renderFull()` renders fenced code blocks and GFM tables in a monospaced font, so AI chat responses stay readable. Table columns align via tab stops with a full-width rule; bullet markers and spacing are normalized.
- **LMKLayout.iconCircle** — 36pt token for the tinted icon circle behind a list-row symbol, with the matching `LMKLayoutTheme` property.
- **UITableViewCell.lmk_configureIconListRow** — One-call standard detail-list row: SF Symbol in a tinted circle (`LMKLayout.iconCircle`), bodyMedium title, caption subtitle, disclosure indicator, and the LumiKit highlight.
- **Keyboard dismiss extensions** — `UITextField.lmk_dismissKeyboardOnReturn()` (Done return key + resign on `.editingDidEndOnExit`, forwarded on `LMKTextField`) and `UIViewController.lmk_dismissKeyboardOnTap()` (tap anywhere outside a field dismisses the keyboard without swallowing control taps).
- **LMKImageUtil.encodeJPEG(_:maxDimension:quality:)** — `nonisolated` downsample + opaque RGBX re-render + `CGImageDestination` encode, so JPEGs stay 3-channel (avoids ImageIO's "AlphaPremulLast" double-memory path) and EXIF orientation is baked into the pixels.

### Fixed

- **LMKPageIndicator** — Display-only when no `pageChangedHandler` is set: taps and VoiceOver increment/decrement no longer move `currentPage` (and the `.adjustable` trait is only advertised while a handler is wired). Previously a tap moved the highlighted dot even with nobody listening, silently desyncing the indicator from the page a controller-driven host was actually showing (e.g. Plantfolio's onboarding; Metamer hit the same trap and has since dropped its dots entirely). Hosts that wire a handler (Petfolio, Example app) are unaffected.
- **LMKSegmentedControl** — The default height constraint yields to host overrides (high priority instead of required), and the hit area inflates to the 44pt minimum touch target.
- **LMKCardView** — Stops double-rounding the inset `contentView`; the outer layer owns the corner radius.

### Infrastructure

- 891 → 992 tests; 112 → 119 source files.
- Example app: new pages for Segmented Pages, Checkbox Cell, Pick & Crop (pick-crop coordinator + single photo viewer), Icon List Row, and Keyboard Dismiss; calendar range picker, markdown code/table, text-input alert, secure text input (`configureField`), and filter-chip multi-select demos added to existing pages. 43 → 51 interactive pages; catalog reorganized from 7 into 9 sections (Lists & Cells and Navigation & Paging split out of Components and Extensions).

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
  - `ignoringTransparent: true` drops pixels with alpha < ~0.9; pair with a subject-lifted PNG (e.g. from `VNGenerateForegroundInstanceMaskRequest`) for hard-edge subject accuracy. `false` (default) drops a 20% border ring instead so typical backgrounds contribute less than the centered subject
- **Live Photo support in `LMKPhotoGrid*` + `LMKPhotoBrowser*`** — Grid cells render a small `livephoto`-symbol LIVE badge when `photoGridIsLivePhoto(at:)` returns true. The browser upgrades a cell from `UIImageView` to `PHLivePhotoView` (same constraints, still visible first) when `photoLivePhoto(at:)` (or the grid-forwarded `photoGridLivePhoto(at:)`) resolves to a non-nil `PHLivePhoto`. Live browser cells show a `livephoto` + "LIVE" capsule stacked directly below the action ("…") button (matching the iOS Photos indicator placement); the badge fades out during active playback and returns on end, driven by `PHLivePhotoViewDelegate`. All new data-source methods have default implementations returning `false`/`nil`, so existing conformers don't need changes. Long-press playback is delegated to `PHLivePhotoView`'s built-in recognizer. Cell reuse is guarded: loads that resolve after the cell has paged away are dropped
- **LMKSegmentedControl `itemSpacing`** — New public property controlling the gap between adjacent segments when scrollable. Default is `LMKSpacing.medium` (12pt), matching the previous hardcoded value. Takes effect after `makeScrollableContainer()` is called; non-scrollable mode always uses 0 spacing since the sliding pill spans full segment bounds. `intrinsicContentSize` accounts for `itemSpacing` in scrollable mode
- **LMKNavigationBar `setRightAccessoryView(_:)` / `setLargeTitleAccessoryView(_:)`** — Two new APIs for non-tappable inline accessories (sync indicators, status icons). `setRightAccessoryView(_:)` parks a view immediately to the left of the right-items stack and survives later `setRightItems(_:)` calls (the accessory lives outside the items stack). `setLargeTitleAccessoryView(_:)` hangs a view off the trailing edge of the large title text (the iOS Mail / Notes pattern), driven by raising the large title's content-hugging priority to `.required` so the accessory tracks the actual text width, not the row width. Pass `nil` to either to remove the existing accessory
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

[Unreleased]: https://github.com/Luminoid/LumiKit/compare/1.0.0...HEAD
[1.0.0]: https://github.com/Luminoid/LumiKit/compare/0.12.0...1.0.0
[0.12.0]: https://github.com/Luminoid/LumiKit/compare/0.11.0...0.12.0
[0.11.0]: https://github.com/Luminoid/LumiKit/compare/0.10.0...0.11.0
[0.10.0]: https://github.com/Luminoid/LumiKit/compare/0.9.0...0.10.0
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
