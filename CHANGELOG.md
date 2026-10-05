# Changelog

All notable changes to LumiKit will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed

- A long navigation bar title no longer squeezes a text item such as Edit onto two lines; the title truncates instead.
- Reassigning `LMKMonthCalendarView.style` with an unchanged look no longer rebuilds the month header each time.

## [1.0.0] - 2026-10-04

LumiKit 1.0 rebuilds the package as a public UI framework: five products, one naming scheme, a theme value that every component follows live, a `Style` on every component, built-in strings in four languages, and the iOS 26 APIs adopted with fallbacks for iOS 18. Every 0.x app needs the migration: read [docs/MIGRATION-1.0.md](docs/MIGRATION-1.0.md), then run `Scripts/migrate-1.0.sh <app-dir> --dry-run`.

### Breaking changes

#### Products

| Old | New | Why |
|---|---|---|
| `LumiKitNetwork` | `LumiKitDebug` | The network logger and its inspector screens ship in one DEBUG-only product |
| Photo browser, grid, crop editor, pick-and-crop coordinator, and share preview in `LumiKitUI` | `LumiKitPhoto` | Apps that never show a photo no longer link PhotosUI |
| `LumiKitUI` depended on `LumiKitNetwork` | `LumiKitUI` depends on `LumiKitCore` and SnapKit only | Link `LumiKitDebug` yourself, under `#if DEBUG` |
| `LMKLottieRefreshControl.animationBundle` defaulted to `.main` and needed an app-supplied JSON | The package bundles its ring animation, tinted from the theme | Delete the app's copy, or pass `animation:` for a custom one |

#### Naming

One naming scheme, documented in [CONTRIBUTING.md](CONTRIBUTING.md). The migration script renames all of these.

| Old | New |
|---|---|
| `LMKConcurrencyHelpers`, `LMKDateHelper`, `LMKDateFormatterHelper`, `LMKFormatHelper`, `LMKFileUtil` | `LMKConcurrency`, `LMKDate`, `LMKDateFormat`, `LMKFormat`, `LMKFile` |
| `LMKAnimationHelper`, `LMKHapticFeedbackHelper`, `LMKDeviceHelper`, `LMKSceneUtil` | `LMKAnimation`, `LMKHaptics`, `LMKDevice`, `LMKScene` |
| `LMKImageUtil`, `LMKDominantColorExtractor`, `LMKQRCodeGenerator` | `LMKImage` (`symbol`, `downsample`, `dominantColor`, `qrCode`); `encodeJPEG(_:maxDimension:quality:)` is `encodeJPEG(_:maxPixelSize:quality:)` and caps in pixels, like `downsample` |
| `LMKAlertPresenter`, `LMKCountdownConfirmation` | `LMKAlert` |
| `LMKShareService`, `LMKPhotoEXIFService`, `LMKDatePickerHelper`, `LMKOverscrollFooterHelper` | `LMKShare`, `LMKPhotoMetadata`, `LMKDatePicker`, `LMKOverscrollFooterView` |
| `LMKBottomSheetController`, `LMKCardPageController`, `LMKCardPanelController`, `LMKSegmentedPageController` | the same names ending in `ViewController` |
| `LMKEnumSelectionBottomSheet` | `LMKEnumPicker` |
| `LMKToastType`, `LMKBannerType` | `LMKStatus` |
| `LMKChipStyle`, `LMKEmptyStateStyle`, `LMKGradientDirection`, `LMKDividerOrientation`, `LMKTipStyle`, `LMKTipArrowDirection`, `LMKTextFieldState` | `LMKChipView.Variant`, `LMKEmptyStateView.Layout`, `LMKGradientView.Direction`, `LMKDividerView.Orientation`, `LMKTipView.Placement`, `LMKTipView.ArrowDirection`, `LMKValidationState` |
| `LMKGlassView.Style`, `LMKProgressViewController.Style`, `LMKSegmentedControl.CornerStyle`, `LMKActionSheet.ActionStyle` | `.Variant`, `.Mode`, `.Corners`, `Action.Style` (`Style` now names each component's style struct) |
| `LMKDeviceType`, `LMKScreenSize`, `LMKButtonRole`, `LMKTypographyType`, `LMKShadowConfig` | `LMKDevice.Kind`, `LMKDevice.ScreenSize`, `LMKButton.Role`, `LMKTypography.Kind`, `LMKShadowTheme.Shadow` |
| `LMKPhotoGridContentMode`, `LMKPhotoGridSortOrder` | `LMKPhotoGridViewController.ContentMode`, `.SortOrder` |
| `LMKRequestData`, `LMKResponseData` | `LMKNetworkRequestRecord.Request`, `.Response` |
| `LMK*Strings` types and `lmk*Strings` globals | nested `Type.Strings`, with `Type.strings` for the whole app and an instance `strings` on types you create |
| `Collection[safe:]`, `String?.nonEmpty`, `NSAttributedString +` | `[lmk_safe:]`, `.lmk_nonEmpty`, `lmk_appending(_:)` |
| `UIControl.lmk_touchAreaEdgeInsets`, `lmk_pointInside` | `lmk_hitTestInsets`, `lmk_point(inside:with:)` (for your own controls; LumiKit controls keep a 44pt target themselves) |
| `URLSessionConfiguration.enableNetworkLogging()` | `lmk_enableNetworkLogging()` |
| `LMKFileUtil.generateTempFileURL(fileExtension:)`, `clearTmpDirectory()` | `LMKFile.temporaryURL(extension:)` (non-optional), `clearTemporaryFiles(olderThan:matchingPrefix:)` |

#### Theme

- The `LMKTheme` protocol, `LMKDefaultTheme`, and `LMKThemeManager` are gone. Colors are an `LMKColorTheme` struct with a fully defaulted initializer, and `LMKTheme` is the whole theme as one value (`colors`, `typography`, `spacing`, `cornerRadius`, `shadow`, `alpha`, `layout`, `animation`, `extensions`) with static `current`, `apply(_:)`, `update(_:)`, `reset()`, `observe(_:)`, and `updates`. An app theme is `extension LMKTheme { static let myApp = LMKTheme(colors: LMKColorTheme(primary: ...)) }`, applied with `LMKTheme.apply(.myApp)`. `configure(colors:typography:...)` and the per-category `apply(spacing:)` are gone.
- Applying a theme re-renders every window: `LMKColor.*` values are dynamic colors, and components restyle themselves. Token reads (`LMKSpacing.large`, `LMKColor.primary`, ...) work from any isolation, so `static let` defaults and SwiftUI views can use them.
- Color roles: `white` to `onAccent`, `black` to `scrim`, `primaryDark` to `primaryVariant`, `imageBorder` to `outline`, `graySoft` to `fillStrong`, `grayMuted` to `fill`; `photoBrowserBackground` to `LMKPhotoBrowserViewController.Style.backgroundColor`. New roles: `link`, `pressedOverlay`, `selection`, and `highContrastBoost` (applied to accents under Increase Contrast).
- `LMKAlpha` is a seven-step ramp with the same values: `overlayLight` to `xxs`, `overlayMedium` to `xs`, `overlayDark` to `small`, `semiTransparent` to `medium`, `overlay` to `large`, `overlayStrong` to `xl`, `overlayOpaque` to `xxl`, `dimmingOverlay` to `dimming`.
- `LMKShadow.small()` / `button()` / `cellCard()` / `card()` / `medium()` / `large()` became `LMKShadow.style(for: .level1 ... .level5)`; `LMKShadow.opacity` became `iconOverlayOpacity`.
- `LMKAnimation.Duration` has seven steps: `buttonPress` to `instant`; `uiShort` and `photoLoad` to `fast`; `actionSheet` and `alert` to `normal`; `modalPresentation`, `listUpdate`, `listInsertDelete`, and `cardExpand` to `moderate`; `screenTransition` and `errorShake` to `slow`; `successFeedback` to `emphasis`. `Spring` and `Curve` are value types on `LMKAnimation`.
- The factories are gone: `LMKButtonFactory.filled(role:title:)` became `LMKButton(title:style: .filled(.role))`, `LMKLabelFactory.caption(text:)` became `UILabel.lmk_make(.caption, text:)`, `LMKCardFactory.cardView()` became `LMKCardView(style: .cell)`. `LMKButton.Style` presets take an `LMKButton.Role`, not a color (`.filled(.destructive)`); `.tint(_:)` sets a custom color.
- The layout constants (`LMKBottomSheetLayout`, `LMKCardPageLayout`, `LMKCardPanelLayout`, `LMKTipLayout`, `LMKFloatingButtonLayout`, `LMKPhotoBrowserConfig`, `LMKBadgeTheme` with `LMKBadge`) and the overridable appearance properties on the base controllers moved into each component's `Style`; the search bar metrics in `LMKLayout` live on `LMKSearchBar.Style`.

#### Presentation

- Anything that presents from a view controller takes `from:`: `LMKAlert`, `LMKErrorHandler`, `LMKActionSheet`, `LMKEnumPicker`, `LMKDatePicker`, `LMKShare`, the photo browser, sheets, and panels. Views shown inside a hierarchy use `show(in:)`: toasts, tips, banners, the floating button. Every dismissal is `dismiss()`, and every completion closure is `completion:`.
- `LMKToast`: the ten `showSuccess` / `showSuccessOnWindow` entry points became `LMKToast.show(_ status:_ message:duration:in:completion:)`, `show(LMKToast.Configuration)`, and `dismissAll(in:)`. With no host, a toast shows on the active window, above presented sheets.
- `LMKBottomSheetViewController.addAsChild(sheet, in:)` and `LMKCardPanelViewController.show(panel, in:)` became the instance method `present(from:)`; `dismissSheet()` became `dismiss(reason:completion:)` and `dismissPanel(completion:)` became `dismiss(completion:)`, both safe to call twice; `init(cancelTitle:)` became `init(style:)` with the title on `strings`. `animateIn()` and `animateOut(velocity:completion:)` are no longer public. UIKit's `dismiss(animated:completion:)` on a sheet or panel runs the component's own dismissal.
- `LMKActionSheet` is a namespace: build an `LMKActionSheet.Configuration` and call `LMKActionSheet.present(_:from:)`; the view controller is `LMKActionSheetViewController`. Custom content sizes itself (`contentHeight:` is gone).
- `LMKEnumPicker.present(from:title:options:selection:onSelect:onCancel:)` handles single (`T?`) and multiple (`Set<T>`) selection; `presentMultiSelect` is gone. `LMKEnumSelectable.iconName` is `String?` and defaults to `nil`.
- `LMKDatePicker.present(_ configuration:from:onConfirm:)` with `Configuration`, `.past(...)`, and `.future(...)`, plus `presentRange`, `presentCalendarRange`, and `presentWithTextField`, replace the seven presenters; every form takes an `onCancel`. `makePicker(_:)` builds a picker whose style works under the Mac idiom.
- `LMKAlert.presentTextInput(TextInput, from:onSave:onCancel:)`, `presentActionSheet(actions: [LMKAlert.Action], from:anchor:onCancel:)`, `presentDeleteConfirmation`, `presentCountdownConfirmation`, and `confirm(...) async -> Bool` replace the parameter-heavy forms; `LMKErrorHandler.present(from:)`. `confirm` and `LMKErrorHandler.confirmRetry` return `false` when the alert cannot be shown or goes away without an action.
- `LMKFloatingButton` has no shared instance: keep the button returned by `show(icon:in:positionKey:onTap:)` and call `dismiss()` on it.
- `LMKShare.present(_ items:from:anchor:completion:)` shares images, files, text, and links in one sheet. `file(at:)` keeps the file unless you pass `deletesAfterShare: true` (0.x `shareFile` always deleted it).

#### Callbacks

- Closures are named `on<Event>` and carry the new value: `tapHandler` to `onTap`, `actionHandler` to `onAction`, `dismissHandler` to `onDismiss`, `valueChangedHandler` and `stateChangedHandler` to `onValueChange`, `textChangedHandler` to `onTextChange`, `pageChangedHandler` to `onPageChange`, `selectionChangedHandler` and `multiSelectionChangedHandler` to `onSelectionChange` (`Set<Int>`), `backAction` to `onBack`. `LMKButton.didTapHandler` is gone. Two payloads changed: `LMKTextField` / `LMKTextView.onTextChange` carries `String` (0.x carried `String?`), and `LMKCheckboxCell.onValueChange` carries the new `isDone` (0.x `onToggle` carried nothing). Every presenter that can be cancelled offers `onCancel`.
- Single-method delegates became closures: `LMKSearchBarDelegate` (`onTextChange`, `onSearch`, `onBeginEditing`, `onEndEditing`, `onCancel`), `LMKPhotoCropDelegate` (`onCrop`, `onCancel`), `LMKSharePreviewDelegate` (`onShare`, `onSave`, `onFailure`). The photo browser and grid data sources and delegates stay.
- `LMKBottomSheetViewController.onDismissTapped()` became `onDismiss: ((DismissReason) -> Void)?` with `cancelButton`, `dimmingTap`, `drag`, `keyCommand`, and `programmatic` reasons.

#### Localization

- Every user-visible default comes from the package's string tables (English, Spanish, Simplified Chinese, Traditional Chinese) through nested `Strings` structs. Apps that localized LumiKit's strings themselves can delete those overrides; apps in other languages set `Type.strings` once at launch, or `instance.strings` per view.

#### Logging

- `LMKLogLevel` has six cases, `debug`, `info`, `notice`, `warning`, `error`, and `fault`, so an exhaustive `switch` needs the two new ones. `warning` now logs at the unified log's error type (it was default), and `notice` at default, the lowest type the device keeps.
- Debug lines are no longer compiled out of Release builds. `minimumLevel` filters at runtime: `.debug` by default in DEBUG builds, `.info` otherwise. A threshold above `.error` is treated as `.error`, so errors and faults are always written.
- An attached error is logged as a public summary with its domain and code (`failed [NSURLErrorDomain -1001 <- NSPOSIXErrorDomain 60]`) plus its full description as private detail, in place of `| Error: <localizedDescription>`.
- `LMKLogging.log` gained a `privateDetail: String?` parameter; a custom conformer adds it.
- LumiKit's own lines moved from `.general`, `.ui`, `.data`, `.network`, and `.error` to the `.lumiKit` category.

#### Removed

| Removed | Use instead |
|---|---|
| `LMKToggleButton` | `LMKButton` with `isToggle = true`, `selectedTitle` / `selectedImage`, `onValueChange` |
| `LMKPhotoGridViewController` as the browser's `LMKPhotoBrowserDataSource` / `LMKPhotoBrowserDelegate` (`numberOfPhotos`, `photo(at:)`, `photoDate(at:)`, and the other display-index members) | Ask your own data source (display order follows `sortOrder`), and reach the presented browser through `grid.browser` |
| `LMKKeyboardInsetHelper`; `LMKKeyboardObserver` is internal | `scrollView.lmk_enableKeyboardAdjustment()` / `lmk_disableKeyboardAdjustment()` |
| `UIView.lmk_fadeIn` / `lmk_fadeOut` | `LMKAnimation.fadeIn(_:)` / `fadeOut(_:)` |
| `lmk_safeAreaSnp`, `lmk_setEdgesEqualToSuperview`, `lmk_centerInSuperview`, `lmk_setAutoLayoutSize` | plain SnapKit |
| `UITableView.lmk_configureCellHighlight`, `UIButton.lmk_animatePress` | `cell.lmk_configureCustomHighlight()`, `LMKAnimation.animateButtonPress(_:)` |
| `lmk_configureIconListRow`, `lmk_emptyStateCell` | `cell.lmk_applyListRow(LMKListRowConfiguration(...))`; host an `LMKEmptyStateView` yourself |
| `LMKPhotoEXIFService.extractDate(from: UIImage)` and the other `UIImage` overloads | `LMKPhotoMetadata.read(from:)` on `Data`, a file URL, a `PHPickerResult`, or an `NSItemProvider` (a decoded image has no metadata left to read) |
| `LMKDateFormatterHelper.dateFormatter(...)`, `configure(dateFormat:)` | `LMKDateFormat.string(_:date:time:)`, `LMKDateFormat.preferredDatePattern` |
| `LMKNavigationBar.setLeftItemEnabled(at:)` / `setRightItemEnabled(at:)`, `pinToTop(of:)` | `updateItem(_:_:)` by identifier, `install(in:)` |
| `LMKBottomSheetViewController.containerBottomConstraint`, `refreshSheetColors()` | `additionalBottomInset`, `applyTheme(_:)` |
| `LMKConcurrency.encode` / `decode` returning optionals | the same names throw; `try?` keeps the optional |
| `LMKPhotoBrowserCell`, `LMKCountdownConfirmationViewController`, `LMKNetworkDetailViewController`, `LMKNetworkRequestStore`, `LMKNavigationDirection` | no longer public |

### Added

#### Theming and styling

- A slot on `LMKTheme` for every component (`theme.button`, `theme.chip`, `theme.navigationBar`, `theme.toast`, `theme.monthCalendar`, `theme.photoBrowser`, `theme.lottieRefreshControl`, and the rest), `LMKThemeExtension` for app-defined values, `LMKThemeApplying` with `lmk_startApplyingTheme()`, and `traitCollection.lmkTheme` / `traitOverrides.lmkTheme`, so a window or subtree can preview a theme without changing the app's.
- A `Style` on every component, every field optional (`nil` means the theme decides), with `merging(_:)`, public structural subviews, and a `didApplyStyle` hook that runs last. Shared pieces: `LMKSurfaceStyle` (background clear, solid, gradient, blur, or glass; corners square, fixed, capsule, circle, or concentric; solid, dashed, or inset borders; shadows; content insets), `LMKControlStateStyle` for highlighted, selected, disabled, and focused looks, and `UIView.lmk_apply(surface:defaults:)`. Turn a part off explicitly with `.square`, `LMKBorderStyle.hidden`, or `LMKShadowSource.hidden`. The open base classes (`LMKButton`, `LMKBottomSheetViewController`, `LMKCardPageViewController`, `LMKCardPanelViewController`, `LMKScrollStackViewController`, `LMKSegmentedPageViewController`, `LMKTabBarController`) call `applyContentTheme(_:)`, where a subclass styles its own content. Components that play haptics have a `haptics` style switch.
- Shadows and borders set with `lmk_applyShadow(_:)` and `lmk_applyBorder(...)` follow theme, Dark Mode, and contrast changes.
- Typography: `LMKTextStyle` (`h1` to `h4`, body, caption, and small steps, `custom(LMKFontSpec)`), `lmk_apply(_:color:)` on labels, text fields, and text views, `UILabel.lmk_make(_:text:color:numberOfLines:)`, `LMKTypographyTheme.maximumScale`, and `fontDesign` / `headingFontDesign` for SF Rounded, Serif, or Mono on every step or only the headings. Fixed heights became Dynamic Type minimums.
- Tokens: `LMKLayout.symbolMicro` through `symbolHero`, `rowHeightCompact` / `rowHeight` / `rowHeightComfortable` / `rowHeightEstimated`, `readableContentMaxWidth`; `LMKColor.onFill(_:preferred:)` and `resolved(_:with:)`; `LMKShadow.Level`; `LMKAnimation.Spring`, `Curve`, and `pressScale`.

#### Controls

- `LMKButton`: `Role` by `Variant` (filled, tinted, outlined, ghost, glass, icon-only) by `Size`; highlighted, selected, disabled, and focused looks; `title`, `image`, `setSymbol(_:)`, `isToggle`, `isLoading`, `menu` with `showsMenuIndicator`, `shrinkingTitleToFit(minimumScaleFactor:)`, `minimumHitTarget`, `Style.animatesSymbolChanges` (iOS 26), and `init(title:style:target:action:)`.
- New controls: `LMKCheckbox`, `LMKRatingControl`, `LMKCopyableLabel`, `LMKPhotoButton`, and `LMKActionTile` (with `UIColor.lmk_glyphTint(onLightAccentDarkenBy:)`). `LMKActionTile.Style.glyphMinimumContrast` keeps the glyph readable against the tile in every appearance, `titleMinimumScaleFactor` shrinks a long title, and `minimumHeight` sets a floor; at accessibility text sizes a long press shows the tile's title and glyph. `LMKPhotoButton.onDropImage` accepts an image dragged onto it on iPad and the Mac.
- `LMKSegmentedControl.Layout` (`equalWidth`, `fitContent`, `scrollable(padding:spacing:)`), `setItems`, `insertSegment` / `removeSegment`, and `setEnabled(_:forSegmentAt:)`.
- `LMKSlider` ticks and `neutralValue` (iOS 26), `Style.disabled`, and a VoiceOver value. `LMKTextField` and `LMKTextView` share `LMKTextInputStyle` (with disabled and per-`LMKValidationState` looks), pass every delegate call on to your delegate, report `onBeginEditing` / `onEndEditing`, and count `maxCharacterCount` in characters; the text field has a themable `clearButton`, and the text view grows between `minimumHeight` and `maximumHeight`. `LMKSearchBar` gained `cancelButtonMode`, `debounceInterval` with `onDebouncedTextChange`, vertical `contentInsets`, and a public `textField`.
- Every LumiKit control keeps a 44pt touch target while enabled; a disabled control absorbs touches inside its bounds, as UIKit's controls do.

#### Components

- `LMKStatus` (success, warning, error, info, neutral), shared by toasts, banners, `LMKStatusLabel`, and validation. Toasts: `LMKToast.Configuration` (`title`, `action`, a duration in seconds or persistent, `position`, `presentation`, `queuePolicy`), `LMKToast.Handle` (`dismiss`, `setMessage`), and `LMKToast.showUndo` with a countdown ring, an optional status or glyph, and a position; only Undo or the countdown ends it unless `tapToDismiss` is on, so a tap that misses Undo commits nothing. `LMKAlert.TextInput.additionalActions` adds buttons after Save (such as a destructive Remove), and a secure text input turns off autocorrection and the other text suggestions.
- `LMKBannerView.show(in:below:insetting:insetsScrollView:)`: a banner over a screen sits under its navigation bar, caps its width at the readable width, and pushes the scroll view's content down by its height; `isFloating`, plus `Style.horizontalMargin`, `verticalMargin`, `maxWidth`, and `dismissSymbolPointSize`.
- Tips: `LMKTip` with `LMKTipView.Placement`; a pointed tip's `Style.surface` colors, borders (solid or dashed), and shadows wrap the bubble and its arrow together, and `Style.arrowColor` fills the arrow under a gradient, blur, or glass bubble. A tip is a VoiceOver modal that the escape gesture dismisses.
- `LMKSkeletonView` (placeholder shapes), `LMKGlassView(variant:)` and `LMKGlassContainerView`, `LMKEmptyStateView.Content` with `asContentUnavailableConfiguration()` and `configure(_:animated:)`, `LMKFilterChipBar.SelectionMode`, `LMKCardView` presets (`cell`, `elevated`, `flat`, `outlined`) and `onTap`, angled and radial `LMKGradientView` gradients, an `LMKOverscrollFooterView` that follows its scroll view, `LMKChipView` as a `UIControl` with a selected look and `Variant.tinted`, `LMKPageIndicator` touch targets and right-to-left layout, and `LMKToastView.Style.dismissButton`.
- `LMKChipFlowView` (`theme.chipFlow`): chips, or any views, in lines that wrap at the view's width, with `Style.spacing` and `lineSpacing`; its height follows its width, so a self-sizing cell around it resizes.
- Lists: `LMKListRowConfiguration` (symbol, image, or async image leading; title, subtitle, and detail; disclosure, checkmark, switch, or badge trailing), `LMKListRowContentView` with highlighted and selected looks, `lmk_applyListRow(_:)`, `lmk_installRowPointerInteraction(_:)`, `UIListContentConfiguration.lmk_applyTextStyle` / `lmk_applyLeadingSymbol` / `lmk_applyThumbnail`, and `LMKListTable.makeInsetGrouped()`.
- `LMKMonthCalendarView` with subclassable `LMKCalendarDayCell` and `LMKCalendarDayDecoration` (dots, badges, glyphs), single, range, and multiple selection, swipe paging that respects Reduce Motion, a today mark that follows the device's date and moves at midnight, and day numerals in the locale's digits. Core adds `LMKCalendarDay`, `LMKCalendarMonth`, `LMKCalendarSelection`, and `LMKCalendarSelectionMode`: Gregorian dates whatever calendar you supply, with day and month arithmetic that daylight-saving changes cannot shift.
- Detail cards: `LMKDetailCard` (a header, typed rows: key-value, text, chips, photo strip, progress, navigation, link, rating, image, divider, custom; and actions), `LMKDetailCardView` (`setValue(_:forRowID:)`, `update(rowID:_:)`), and `LMKDetailPageViewController` (cards updated by id, Edit and Share items, Command-E for `onEdit`, `beginEditing` with Command-Return and Escape).
- `LMKMenu`: option menus as native `UIMenu`s built from sections (`single` choice, `multiple` toggles that flip while the menu stays open, `sort` with a direction, `actions`, `submenu`, `custom`), rebuilt from your state each time the menu opens, and anchored to a bar button, a navigation bar item, or an `LMKButton`; `reloadVisibleMenu(presenting:)` repaints an open menu. `LMKSortMenu` adds a sort menu with a live direction arrow, a layout section, and `additionalSections` for filters and commands.
- `LMKTabBarController`, `LMKTab` (lazy roots, a `search` role), and `LMKTabBarAppearance`: `selectTab(identifier:)`, `reorderTabs`, badges, Command-1 to Command-9, the iPad sidebar, `applyContentTheme(_:)`, and the iOS 26 minimize behavior and bottom accessory.

#### Navigation and containers

- `LMKNavigationBar.Style.appearance` (`automatic`, `classic`, `glass`): by default the bar matches the running OS, with Liquid Glass item capsules on iOS 26 and tinted items over a hairline before; `Style.itemGlass` and `itemGlassViews` style the capsules. `LMKNavigationBarItem` has `identifier`, `isEnabled`, `menu`, `badge`, and `role` (plain, prominent, destructive); the bar adds `updateItem(_:_:)`, `install(in:)`, `subtitle`, `backgroundContentView`, and `pinScrollView(_:edgeEffect:)`. Under the Mac idiom, glyph items and the back button show their label as a tooltip. For system bars: `makeBarButtonItem()`, `UINavigationItem.lmk_setItems(leading:trailing:)`, and `lmk_setSubtitle(_:)`.
- `LMKNavigationController` with `LMKPopGestureConfiguring`: the swipe back follows `canBeginPopGesture`, also with the system bar hidden and with the iOS 26 content-area swipe; the top screen sets the status bar style.
- `LMKBottomSheetViewController`: drags that hand off to an inner scroll view, Escape and Command-W, `contentLayoutGuide`, `resolveStyle(for:)` for subclasses, and VoiceOver modal behavior. `LMKActionSheet.Configuration`, `RowStyle.disabled`, and a public `LMKActionSheetRowView`; `LMKEnumPicker` search and disabled options, sized to its rows; `LMKDatePicker.Configuration`; `LMKCalendarRangeSelectionView.Style` and `locale`.
- `LMKCardPageViewController`: `leadingItem` / `trailingItem` (titled items, roles, badges), `usesSystemNavigationBar` (pushed onto a stack whose bar shows, the page hands its title and items to that bar), and `Style.showsDragIndicator` for a page in a sheet. `LMKCardPanelViewController.presentation` (overlay window or modal), `Style.heightRatio`, Escape and Command-W, VoiceOver modal behavior, and `UIViewController.lmk_cardPanel`.
- `LMKScrollStackViewController` and `LMKFormScaffold` width modes (inset, readable, capped), `makeFieldRow`, and `makeHeaderStack`; `LMKSegmentedPageViewController.segmentedControlPlacement` and trackpad swipe paging; `LMKProgressViewController` finished states, `observe(_ progress:)`, and Escape; `LMKErrorHandler.policy`.

#### Core and utilities

- `LMKDateFormat` on `Date.FormatStyle`: `Context` (locale, calendar, time zone, hour cycle), `string(_:date:time:)`, `intervalString`, `rangeLabel`, `residenceLabel`, `relativeDayString`, `clockTime`, `dateWithClockTime`, `usesTwelveHourClock`, `widestClockSample`, `monthYearString`, `weekdaySymbols`, `formatter(pattern:)`, and `preferredDatePattern` for a user-chosen date format. `LMKFormat` number and percent formatting.
- `LMKLogger`: `notice` and `fault`; a runtime `minimumLevel`; `private:` on every level for user data (the message stays public unless `messagePrivacy` says otherwise); `error:` on every level; `describe(_:)`; `once(_:_:_:)` and `resetOnce(_:)` for repeating failures; `record(_:)` for entries another package already wrote; `entryHandler`, `log(_:_:)`, and the `LMKLogging` protocol with `LMKLogger.default`; the `.lumiKit` category; `LMKLogLevel` is `Comparable` with `osLogType`; `LMKLogEntry` is `Codable` and carries `privateDetail`, `file`, `function`, and `line`; `LMKLogStore.formatted()` includes the private detail for on-device debugging.
- `LMKErrorHandler.present` / `confirmRetry` and `LMKConcurrency.executeTask` log your call site. Image encoding and downsampling, photo metadata, the crop editor, the pick-and-crop coordinator, and presenting a share sheet or picker log a warning when they fail.
- `LMKURLValidator.validate(_:)` returns `Result<URL, ValidationError>` with the reason; the blocklist covers more private, reserved, and loopback addresses and host spellings; `normalizeBaseURL(_:preservingPathExtension:)`.
- `LMKFile.temporaryURL(extension:)`, `clearTemporaryFiles(olderThan:matchingPrefix:)`, and `clearTemporaryFilesInBackground(olderThan:matchingPrefix:)`, both returning a count; `LMKConcurrency.encode` / `decode` throw and accept custom coders; `onMainActor` / `onMainActorAfter` return their `Task`; `String.lmk_trimmedOrNil`; `LMKDate.initialize()` is optional.
- `LMKImage.downsample(data:maxPixelSize:options:)` and `downsample(fileURL:...)` (sync and async, with HDR), `pixelSize`, `downsampledJPEG`, `imageSize`, and `SymbolOptions` (palette, hierarchical, and multicolor rendering, variable value, and the iOS 26 modes). `LMKPhotoMetadata` reads from `Data`, a URL, a `PHPickerResult`, or an `NSItemProvider`, and writes a date and coordinate.
- `LMKScene.activeWindowScene`, `keyWindow`, `presentingViewController`, `requestClose(_:onError:)`, `configureMacWindow(for:minimumSize:maximumSize:hidesTitleBar:)`, and `observeGeometry(of:onChange:)` (size, safe areas, orientation, and the iOS 26 interactive-resize flag); `LMKDevice.observeScreenSize(of:onChange:)`; `LMKTheme.observe(_:)` returns a token that ends the observation when released.
- `UIViewController.lmk_formKeyCommands(save:cancel:)` with an overridable `lmk_cancelFromKeyCommand()`, `UIView.lmk_pinReadableWidth(in:)` and `lmk_readableWidthGuide`, `lmk_displayScale`, `lmk_forceLayoutDirection(_:)`, `UIScrollView.lmk_disableKeyboardAdjustment()`, the `UISplitViewController.lmk_setInspector(_:)` family, and `lmk_apply(_:animatingDifferences:in:)` for diffable data sources.
- `LMKMarkdownRenderer.render` and `renderFull` can be called off the main actor.
- WCAG contrast helpers on `UIColor`: `lmk_relativeLuminance(resolvedWith:)`, `lmk_contrastRatio(to:resolvedWith:)`, and `lmk_softestTone(over:washAlpha:minimumContrast:resolvedWith:)`, the softest tone of a color that keeps a contrast ratio against a wash of itself.
- `LMKShare.Item` (image, file, text, url) with `text` / `url` conveniences; `LMKHaptics.isEnabled`; `UIColor.lmk_composited(over:alpha:)` for an opaque tinted surface and `lmk_stateShade(by:)` for pressed and selected fills; `LMKLayout.pixelAligned(_:scale:)` and `pixelAligned(_:for:)` for lines of even thickness.

#### Photo

- Photo browser: `Style` with `theme.photoBrowser`, a zoom transition from `zoomSourceView`, HDR display, an orientation lock on iOS 26, `onDismiss`, key commands, and `stageView`. Gestures: a double tap zooms on the tapped point, a zoomed photo pans to its edges and pages past them, a long press plays a Live Photo, and a trackpad pinch on the Mac zooms around the pointer.
- Grid: `allowsMultipleSelection` with `selectedIndices` and `onSelectionChange` (a sideways drag selects a range and scrolls near the edges), `contextMenuProvider`, prefetch hooks (`photoGridPrefetch`, `photoGridCancelPrefetch`), `photoGridThumbnail(at:pixelSize:)` for thumbnails sized to the cell, `browser` for the presented browser, drag and drop with other apps (`allowsDraggingPhotos`, which carries the photo's original file when the data source implements `photoGridFileURL(at:)`, and `onDropImages`, both off by default), a pinch that changes the column count around the fingers (`Style.pinchFeedback`), a floating glass toolbar, and the top scroll-edge effect. `LMKSinglePhotoViewer.browser` and `dismiss(completion:)`.
- Crop editor: `aspectRatios` and `initialAspectRatio` (`LMKCropAspectRatio` gains 16:9 and 9:16), `onCrop` / `onCancel`, keyboard shortcuts, and a crop frame VoiceOver can move and resize.
- Pick-and-crop coordinator: `save(image, metadata) async`, `onPicked`, `onCancel`, `onFailure` (`Failure` is a `LocalizedError`; with no handler, failures show through `LMKErrorHandler`), `Strings`, and `maximumPixelSize`.
- Share preview: `detents`, `onShare` / `onSave` / `onFailure` / `onDismiss`, and `isSaving`; Save Image shows only when the app declares `NSPhotoLibraryAddUsageDescription`, unless `Style.showsSaveButton` says otherwise.
- `LMKPhotoMetadata.write` keeps the image data intact (every frame and gain map) and writes EXIF dates with their time-zone offset; `read` honors them.

#### Debug

- `LMKNetworkLogger.Configuration`: credential redaction on by default for the common auth, cookie, and API-key headers (`redactedHeaderFields`) and query items (`redactedQueryItems`), applied to the URL, a `Location` header, and a URL password; `hostFilter`, body caps, and `recordsDidChangeNotification`; `redact(_:configuration:)` and `record(id:)`.
- Request bodies are captured (`isBodyTruncated` says when the cap cut one), logged requests keep the app's cookies, cache, and credentials, and redirects go back to the app's session, which decides whether to follow them; both hops are recorded. While logging is on, a refused redirect completes about half a second later.
- `LMKNetworkRequestRecord.outcome` (`pending`, `success`, `redirect`, `error`) and `isRedirect`, next to `isSuccess` and `isError`. `LMKNetworkHistoryViewController` lists records with an icon per outcome and an empty state, and its localized detail screen copies to a pasteboard entry that expires. The whole product compiles only under `LMK_ENABLE_NETWORK_LOGGING`.

#### Lottie

- The bundled ring, tinted from `theme.lottieRefreshControl`; `Style` (`pullThreshold`, `timeline`, `minimumSpinDuration`, `size`, tint); `Timeline(animation:)` for your own animation (split at a `PHASE2_SPIN_LOOP` marker, or looped whole); `install(on:style:onRefresh:)`; and `makeRefreshKeyCommand(action:)` for Command-R. The ring follows appearance, contrast, and Reduce Motion changes.

#### Platform

- iOS 26 APIs with fallbacks for iOS 18: Liquid Glass surfaces and glass buttons, concentric corners, scroll-edge effects, tab bar minimize behavior and bottom accessory, `UISearchTab`, navigation subtitles, prominent bar items with badges, slider ticks and neutral value, symbol transitions and rendering modes, the split view inspector column, HDR headroom, right-to-left natural alignment, interactive resizing, orientation lock, and background extension views. [docs/PLATFORM.md](docs/PLATFORM.md) lists each one and the iOS 27 follow-ups.
- Mac Catalyst: every component works under the Mac idiom; there the Lottie refresh control returns `nil` from `install` and offers Command-R instead.

#### Documentation and tooling

- DocC documentation for all five products, [docs/MIGRATION-1.0.md](docs/MIGRATION-1.0.md), [docs/PLATFORM.md](docs/PLATFORM.md), CONTRIBUTING.md, and SECURITY.md.
- `Scripts/migrate-1.0.sh` renames types, members, and call shapes in your app and reports, by file and line, the edits to make by hand; `--dry-run` shows the changes without writing them.
- An Example app with a page for every component, a catalog search, a theme switcher, and a scripted accessibility check (truncation, clipping, overlap, touch targets, labels, contrast, and fixed fonts) across every page.

### Changed

Defaults an app upgrading from 0.12 will see differently.

- `LMKDevice.screenSize` classifies by the window's portrait width and size classes instead of the screen height: up to 375pt is `.compact`, up to 402pt `.regular`, wider `.large`, and only a window regular in both size classes is `.extraLarge`. iPhone mini, X, and 11 Pro now read `.compact`, iPhone 14 Pro through 17 Pro read `.regular`, and an iPad in Slide Over or a narrow split is no longer `.extraLarge`. `LMKSpacing.cardPadding` and `cellPaddingVertical` follow: iPads step by window size instead of all getting the large values, and narrow windows get phone spacing.
- On iOS 26, `LMKNavigationBar` draws its items on Liquid Glass with no hairline, like the system bar. `theme.navigationBar.appearance = .classic` keeps the 0.12 look.
- `LMKButton`: every button now shrinks slightly and plays a light haptic when pressed (0.12 did this only for buttons given a style); `Style.pressAnimation` and `Style.haptics` turn them off. A button that opens its `menu` on tap does not shrink. While `isLoading` is on, taps no longer fall through to the views behind it, VoiceOver still reads the title, and an icon-only button keeps its width. Under the Mac idiom, buttons keep their iOS look instead of drawing as bare titles.
- Chips: a selected filled `LMKChipView` shows a darker fill instead of switching to an outline (`Style.selectedVariant = .outlined` keeps the 0.12 swap), and a tappable chip shows a pressed look. An `LMKFilterChipBar` with a filled chip style draws unselected chips in a soft tint and the selected chip fully filled.
- `LMKBannerView` has an opaque tinted background with a thin border in the status color, larger corners, and a smaller dismiss glyph, in place of 0.12's translucent tint.
- `LMKPhotoBrowserViewController` and `LMKPhotoCropViewController` present full screen on their own (0.12 showed them as a sheet when presented directly). The browser presents over the screen it came from, so a dismiss drag reveals that screen; set `modalPresentationStyle = .fullScreen` for a black backdrop. A dismiss drag moves the photo with the finger at full size and fades only the background, where 0.12 shrank the photo and faded the whole browser.
- In a regular-width window (iPad, Mac), `LMKBottomSheetViewController` and the action sheet and enum picker built on it are capped at `Style.maxWidth` (the readable width by default) and centered, instead of spanning the whole window.
- `LMKTipView` keeps its bubble inside the safe area, and `.automatic` placement picks above or below by the room on each side. VoiceOver reads the tap-anywhere area as "Got it, button".
- `LMKLoadingStateView` stays hidden until `startLoading()`; an inline view without a set height sizes to its content.
- `LMKBadgeView` keeps its own size in stack views. `lmk_makeCircular()` keeps a view round as its size changes. Views inside `LMKGradientView` are reachable by VoiceOver.
- `LMKSwitch`'s thumb uses `LMKColor.onAccent` instead of pure white; `Style.thumbTint = .white` keeps the 0.12 thumb.
- With no value given, `LMKColorTheme.primaryVariant` is an opaque, slightly darker shade of `primary` (0.12's `primaryDark` default was translucent green), and `outline` is `divider` at half opacity. Pass both to `LMKColorTheme(...)` to keep your 0.12 colors.
- Small text (`.small`, `.extraSmall`) and the helper text and character counter of `LMKTextField` and `LMKTextView` default to `LMKColor.textSecondary` instead of `textTertiary`, to meet WCAG AA contrast.
- Labels made with `UILabel.lmk_make` align natural text to the interface's layout direction, like a plain `UILabel`; 0.12's factory labels followed the text's own direction.
- `UIColor(lmk_hex:)` returns `nil` for a string with any non-hex character; 0.12 parsed the valid leading part.
- `LMKLogEntry.message` holds only the logged text, with the call site in `file`, `function`, and `line`; `formattedMessage` gives the 0.12 string, and `LMKLogStore.formatted()` still includes the call site.
- `LMKNetworkRequestRecord.isError` no longer counts a 3xx response: 304 Not Modified is `isSuccess`, other 3xx responses are `isRedirect`, and a record with a transport error is `isError` and never `isSuccess`. `displayDuration` follows the locale ("2,500ms").

### Fixed

Bugs present in 0.12.

#### Controls and text input

- `LMKSwitch` and `LMKSegmentedControl` ignored `isEnabled`: a disabled control looked the same and still changed value. `LMKSwitch.setOn(_:animated:)` never animated.
- A vertical scroll that started on an `LMKSegmentedControl` was taken by its indicator drag, and taps near its edges did nothing. A segmented control sized to its titles could collapse a segment at large text sizes.
- `LMKSlider` crashed in Mac Catalyst apps that use the Mac idiom.
- `LMKSlider`, `LMKSearchBar`, the `LMKCardPageViewController` header buttons, and the `LMKSharePreviewViewController` close button had touch targets smaller than 44pt. `LMKPageIndicator` had no VoiceOver label.
- A display-only `LMKChipView` swallowed taps meant for the view behind it, such as a table cell. Outlined chip borders could look thicker on some edges than on others on 3x screens.
- `LMKTextField` and `LMKTextView` counted `maxCharacterCount` in UTF-16 units, so an emoji used up several characters; they blocked input-method composition near the limit and rejected an over-long paste instead of keeping what fit. `LMKTextField`'s clear button never appeared, and `LMKTextView` helper text could wrap one word per line.

#### Sheets, panels, and navigation

- Bottom sheets: a tall sheet lifted by the keyboard could rise above the top safe area, a sheet presented while the keyboard was up sat behind it, and a dismissed sheet could not be presented again. Rows in a multi-page `LMKActionSheet` stayed tappable during the page slide, so a tap could run an action from the wrong page. `LMKEnumPicker` rows had a fixed height and clipped at large text sizes. `LMKDatePicker.presentRange` leaked its pickers.
- `LMKCardPanelViewController` ignored safe areas, did not give key-window status back to the window underneath after an overlay panel closed, and dropped touches meant for a controller the panel presented.
- `LMKCardPageViewController` drew its header under the status bar, or under the Mac window controls, when the page filled the screen, and setting `title` after the view loaded did not update the header.
- `LMKNavigationBar` ignored the left and right safe-area insets, so in landscape its items could sit under the sensor housing.
- `LMKScrollStackViewController` and `LMKFormScaffold` measured their content from the screen edges, so on iOS 26 content slid under a floating tab bar or split view sidebar, and in landscape under the sensor housing.
- `LMKSegmentedPageViewController`: tapping a segment during a page slide moved the control without changing the page, the page swipe fired alongside sliders and the indicator drag, `setPage(_:animated:)` before the view loaded was ignored, and the first page was laid out at zero width. Under the Mac idiom the segmented control did not show; it now sits in the window toolbar.
- Under the Mac idiom, an `LMKNavigationController` with a visible bar lost its toolbar back button after a full-screen presentation over it closed, and after a presented split view closed its back button and title sat a sidebar's width in from the window controls.
- `lmk_topViewController` recursed until it crashed on an empty navigation controller, and `lmk_presentAlertOnTop` re-centered an action sheet popover that was already anchored to a view.

#### Feedback and status

- A banner shown over a screen covered the content without making room for it and let the content show through, and with Reduce Motion on a dismissed banner shown again stayed invisible.
- A pointed tip stayed where it first appeared after a rotation or resize, and `dismiss()` could call `onDismiss` twice.
- `LMKFloatingButton` kept its old position when the window rotated or resized, and a drag could leave it under a side safe-area inset.
- `LMKEmptyStateView` could show its message one word per line when first laid out at zero width, as a table background is. `LMKLoadingStateView` logged a broken constraint as a table background.
- `LMKAlert.presentCountdownConfirmation` with a long message grew taller than the screen and pushed its buttons out of reach.
- In right-to-left layouts an overflowing `LMKFilterChipBar` opened on its last chips. `LMKPageIndicator` crashed on a negative page count. The skeleton shimmer stopped for good after the app went to the background.

#### Photo

- Photo browser: a zoomed photo could be panned past its edges, and a double tap zoomed on a different point than the one tapped. A dismiss drag faded the photo along with the background. A swipe made while the browser was opening was undone, and the browser jumped back to its first photo whenever it reappeared. Rotating or resizing left the pages misaligned. At 1x, the first sideways drag on a narrow photo moved the photo instead of paging. Releasing a pinch past the maximum zoom brought the controls back over the photo, and the LIVE badge stayed when the other controls hid. In right-to-left layouts the pages and arrow keys ran the wrong way, and on the Mac paging while zoomed left the controls hidden.
- Photo grid cells held full-size images, which used a lot of memory.
- Crop editor: it made a full-size copy of the photo before cropping, could lose a locked aspect ratio, and took a pinch only with both fingers outside the crop frame. Pick-and-crop could fail to show the crop editor when the photo loaded before the picker finished closing.
- Share preview: tapping Save twice saved twice; Save in an app without `NSPhotoLibraryAddUsageDescription` went to the photo library anyway (which terminates the app) instead of reporting `.photoLibraryAccessDenied`; and a failed write that came back without an error was neither logged nor reported.

#### Core and utilities

- Reading `LMKDevice.deviceType`, `isIPad`, or `isMacCatalyst` off the main thread crashed, and `LMKDevice.hasTopNotch` returned `true` on iPads.
- `LMKDate.calendar` and the helpers built on it (`today`, `isToday`, `startOfDay`) kept the launch time zone after a time-zone change unless the app had called `LMKDate.initialize()`.
- `LMKURLValidator` accepted loopback and private addresses written in shorthand, octal, or hex IPv4 form (`127.1`, `0177.0.0.1`), and `*.localhost` hosts.
- `UIScrollView.lmk_enableKeyboardAdjustment()` scrolled a focused text view that was itself the adjusted scroll view, and left extra space above the keyboard.
- `LMKMarkdownRenderer` could style the wrong line as a heading, and missed tables in text with Windows (CRLF) line endings.
- Under Reduce Motion, `LMKAnimation.animateErrorShake` removed the view's own border.
- A cell using `lmk_applyCustomHighlight(highlighted:animated:)` could lose its highlight when pressed again during the un-highlight.
- `LMKShadowStyle` had no public initializer.
- Calling `LMKLogger.configure(subsystem:)` while other threads were logging was a data race.

#### Debug and Lottie

- With network logging on, request bodies were never recorded, redirects were followed without the app's session seeing them, and logged requests dropped the app's cookies, cache, and credentials. Sessions set up with `lmk_enableNetworkLogging()` kept being intercepted after `LMKNetworkLogger.disable()`.
- `LMKLottieRefreshControl` started a refresh after the pull went back below the threshold, or on a bounce or a programmatic scroll, and showed a still ring when UIKit started the refresh before the finger lifted.

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
