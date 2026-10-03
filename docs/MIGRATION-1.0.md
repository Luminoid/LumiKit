# Migrating to LumiKit 1.0

LumiKit 1.0 renames most of the public surface, splits the package into five products, replaces the theme manager with a value type, and turns every component's appearance knobs into a `Style` struct. This guide takes a 0.12 consumer to 1.0 in four steps: pick the products, run the script, apply the hand edits it reports, and build. The CHANGELOG's `1.0.0` section explains why each change was made; this page is about what to type.

## 1. Products and imports

| You use | Link | Import |
|---|---|---|
| Tokens, components, controls, alerts, utilities | `LumiKitUI` | `import LumiKitUI` |
| Foundation-only helpers (logging, dates, validation) | `LumiKitCore` | `import LumiKitCore` in each file that names a Core type (linking `LumiKitUI` brings the module along; it is not re-exported) |
| Photo browser, photo grid, crop editor, pick-and-crop coordinator, share preview, `LMKPhotoMetadata` | `LumiKitPhoto` | `import LumiKitPhoto` in each file that names one of those types |
| Network logging and the request inspector | `LumiKitDebug` (formerly `LumiKitNetwork`) | `import LumiKitDebug` under `#if DEBUG` |
| Lottie pull-to-refresh | `LumiKitLottie` | `import LumiKitLottie` |

`LumiKitUI` no longer pulls in the network logger, so an app that used it only through the transitive dependency must add `LumiKitDebug` to its target. The script inserts the `LumiKitPhoto` and `LumiKitDebug` imports where it can (after an existing `import LumiKitUI`) and lists the files it could not.

## 2. Run the script

```bash
# From the LumiKit checkout (the `make migrate` target wraps the same call):
Scripts/migrate-1.0.sh ../MyApp --dry-run    # counts and the report (computed over a rewritten mirror), nothing written
Scripts/migrate-1.0.sh ../MyApp              # rewrite, then print the report
Scripts/migrate-1.0.sh ../MyApp --docs       # also rewrite *.md
```

- Commit or stash first. A consumer inside a git work tree with uncommitted changes is refused (nothing else can undo the rewrite); `--allow-dirty` overrides that. The script also refuses to run over the LumiKit checkout it lives in, and skips a LumiKit checkout vendored inside the consumer.
- The script edits `*.swift`, `project.pbxproj`, `Package.swift`, and `project.yml` under the directory, skipping `.build`, `DerivedData`, `build`, `Pods`, and `node_modules`.
- Passes run in a fixed order: product names, dotted paths written against the old type name, one simultaneous rename of type identifiers (this is what makes the `LMKThemeManager` to `LMKTheme` and `LMKTheme` to `LMKColorTheme` swap safe), call-shape regexes, type-blind member renames (`--no-members` skips them if a name collides with your own API), and file-conditional edits.
- The run is not idempotent because `LMKTheme` is both an old and a new name. A `.lumikit-1.0-migrated` marker at the consumer root blocks a second run; `--force` overrides it once you have reverted to a pre-migration tree.
- The exit status is `2` while any `remove:` recipe still matches (removed API is still referenced), `0` once the tree only needs review-level edits.

The report lists every hand edit by file and line with the recipe from the tables at the end of this page. Work through the `remove:` items first (they will not compile), then the `reshape:` items, then the `Review` items.

## 3. Recipes for the hand edits

### Theme

```swift
// 0.x
struct MyAppTheme: LMKTheme {
    var primary: UIColor { ... }
    var secondary: UIColor { ... }
    // 19 more requirements
}
LMKThemeManager.shared.configure(colors: MyAppTheme(), spacing: .init(large: 20))

// 1.0
extension LMKTheme {
    static let myApp = LMKTheme(
        colors: LMKColorTheme(primary: ..., secondary: ...),   // only the roles that differ
        spacing: LMKSpacingTheme(large: 20)
    )
}
LMKTheme.apply(.myApp)                                          // at launch, and any time later
LMKTheme.update { $0.spacing.large = 24 }                       // per-category apply(spacing:) is gone
let large = LMKTheme.current.spacing.large                      // readable from any isolation
```

Every `LMKColor.*` token is a dynamic color that re-resolves when a theme is applied, so views need no re-assignment. `CGColor` sinks go through `lmk_applyShadow` / `lmk_applyBorder`, which re-stamp on theme, dark mode, and contrast changes. Per-component defaults live on the theme (`theme.button.variant = .tinted`); app-specific values conform to `LMKThemeExtension` and live in `theme[MyAccents.self]`.

### Component styles

Appearance properties became fields on the component's `Style`:

```swift
chip.chipColor = .systemPink            // 0.x
chip.style = .filled.tint(.systemPink)  // 1.0, or chip.style.tintColor = .systemPink

card.cardCornerRadius = 20              // 0.x
card.style.surface.corners = .fixed(20) // 1.0
```

Base-controller overrides (`override var headerHeight`, `cardMaxWidth`, `stackSpacing`, ...) became `style.<field> = ...` in `init`; the panel's `cardMaxHeightRatio` is `LMKCardPanelViewController.Style.heightRatio`, an exact height fraction rather than a cap. Behavior hooks (`usesFullWidthSwipe`, `dismissesOnBackgroundTap`) stay overridable. Subclasses that styled their content after `super.applyTheme(_:)` do it in `applyContentTheme(_:)` instead, which every open base calls just before `didApplyStyle`.

### Buttons and labels

```swift
LMKButtonFactory.filled(role: .destructive, title: "Delete", target: self, action: #selector(delete))
LMKButton(title: "Delete", style: .filled(.destructive), target: self, action: #selector(delete))

button.applyStyle(.filled(LMKColor.primary), title: "Save")
button.style = .filled(.primary); button.title = "Save"

button.didTapHandler = { [weak self] button in ... }
button.onTap = { [weak self] in ... }           // capture the button if you need it

LMKLabelFactory.caption(text: "Hint")
UILabel.lmk_make(.caption, text: "Hint")
```

### Presenting

```swift
LMKBottomSheetController.addAsChild(sheet, in: self)   // 0.x
sheet.present(from: self)                              // 1.0

LMKCardPanelController.show(panel, in: window)         // 0.x
panel.present(from: self)                              // 1.0

LMKToast.showSuccess(message: "Saved", on: self)       // 0.x
LMKToast.show(.success, "Saved", in: self)             // 1.0 (no host: the active window scene)

LMKAlertPresenter.presentAlert(on: self, title: ...)   // 0.x
LMKAlert.present(from: self, title: ...)               // 1.0
```

The script renames `on:` to `from:` (or `in:` for toasts and tips) when the label sits on the same line as the call; a multi-line call is reported for a manual rename.

### Delegates that became closures

```swift
searchBar.delegate = self                               // 0.x, plus 5 delegate methods
searchBar.onTextChange = { text in ... }                // 1.0
searchBar.onSearch = { text in ... }
searchBar.onCancel = { ... }

let crop = LMKPhotoCropViewController(image: image, delegate: self)   // 0.x
let crop = LMKPhotoCropViewController(image: image)                   // 1.0
crop.onCrop = { image in ... }
crop.onCancel = { ... }
```

`LMKSharePreviewViewController` follows the same pattern with `onShare`, `onSave`, `onFailure`, and `onDismiss`.

Closures that already existed keep their names through the member pass but two payloads changed: `LMKTextField` / `LMKTextView.onTextChange` (0.x `textChangedHandler`) carries `String`, not `String?`, and `LMKCheckboxCell.onValueChange` (0.x `onToggle`) carries the new `isDone`. `LMKShare.file(at:)` keeps the shared file unless `deletesAfterShare: true` is passed (0.x `shareFile` always deleted it), and `LMKImage.encodeJPEG(_:maxPixelSize:quality:)` caps in pixels where 0.x `maxDimension:` was in points.

### Enum pickers

`LMKEnumSelectable.iconName` is `String?` with a default of `nil`. A conformance that declared `var iconName: String { ... }` changes the type (the script does this in files that mention `LMKEnumSelectable`) or deletes the property. Multi-select is a selection type, not a method:

```swift
LMKEnumPicker.present(from: self, title: "Sort", options: SortField.allCases, selection: current) { chosen in ... }          // T?
LMKEnumPicker.present(from: self, title: "Tags", options: Tag.allCases, selection: chosen) { set in ... }                   // Set<T>
```

### Photo metadata

```swift
let date = LMKPhotoEXIFService.extractDate(from: uiImage)          // 0.x: a decoded image has no EXIF
let metadata = await LMKPhotoMetadata.read(from: pickerResult)     // 1.0: read the picked bytes once
let date = metadata.date
let coordinate = metadata.coordinate
```

`LMKPhotoPickCropCoordinator` hands the metadata to its `save` closure: `save: { image, metadata async -> String? in ... }`.

### Core helpers

```swift
let data = LMKConcurrencyHelpers.encode(value)          // 0.x: Data?
let data = try? LMKConcurrency.encode(value)            // 1.0: the script inserts `try?`; drop it to propagate the error

let url = LMKFileUtil.generateTempFileURL(fileExtension: .jpeg)   // 0.x: URL?
let url = LMKFile.temporaryURL(extension: .jpeg)                  // 1.0: URL

LMKDateFormatterHelper.formatDate(date, includeTime: true)   // 0.x
LMKDateFormat.string(date, includeTime: true)                // 1.0, or string(date, date: .medium, time: .short); a stored user pattern goes through preferredDatePattern
```

### Strings

Every configurable string is a nested `Strings` on its owner, with localized defaults in `en`, `es`, `zh-Hans`, and `zh-Hant`:

```swift
lmkPhotoCropStrings = LMKPhotoCropStrings(cancel: "Abbrechen")           // 0.x
LMKPhotoCropViewController.strings = .init(cancel: "Abbrechen")          // 1.0, process-wide
cropViewController.strings = .init(cancel: "Abbrechen")                  // 1.0, per instance
```

An app that already ships one of the four package languages can delete its LumiKit string overrides.

### Subclasses under Swift 6.4 (Xcode 27)

LumiKit's view controllers deinitialize on the main actor, and Swift 6.4 checks that an override matches. A subclass with a plain `deinit` fails with "nonisolated deinitializer 'deinit' has different actor isolation from main actor-isolated overridden declaration". Declare it `isolated`:

```swift
final class MainTabBarController: LMKTabBarController {
    isolated deinit {
        refreshTask?.cancel()
    }
}
```

A `deinit` that only removed selector-based `NotificationCenter` observers can be deleted, since those observers unregister themselves.

### Content goes through the component, not the UIKit object behind it

An `LMKButton` rebuilds its `UIButton.Configuration` from `title`, `image`, and `style` on every theme, Dynamic Type, and state pass, so a value written straight into the configuration is lost at the next pass:

```swift
button.configuration?.title = name      // 0.x habit: reverts on the next dark mode switch
button.title = name                     // 1.0
```

### App components with a LumiKit counterpart

LumiKit now ships counterparts for things apps tend to write themselves: month calendar grids (`LMKMonthCalendarView`), sort menus (`LMKSortMenu`), tab bar controllers (`LMKTabBarController`), detail card chrome (`LMKDetailPageViewController`), list cells (`LMKListRowConfiguration`), action tiles, star ratings, copyable labels, photo buttons, checkboxes, date formatter caches (`LMKDateFormat`), image downsamplers (`LMKImage.downsample`), EXIF writers (`LMKPhotoMetadata.write`), Mac window configuration (`LMKScene.configureMacWindow`), and form key commands (`lmk_formKeyCommands`). The last group of report recipes looks for such copies by the names they had in the apps LumiKit grew out of, so it flags little in another code base; search for your own. Adopting them is optional but each replaces a hundred or more lines.

## 4. Checklist

- [ ] Products linked and imports added (`LumiKitPhoto`, `LumiKitDebug` under `#if DEBUG`).
- [ ] Script run; report has no `remove:` items.
- [ ] Theme converted to `extension LMKTheme { static let x }` and `LMKTheme.apply(.x)` at launch.
- [ ] `on:` labels on multi-line calls renamed to `from:` / `in:`.
- [ ] Delegates replaced by closures (search bar, crop, share preview).
- [ ] `LMKEnumSelectable.iconName` conformances updated.
- [ ] Dead `lmk_hitTestInsets` assignments deleted (LumiKit controls enforce 44pt themselves).
- [ ] App copies of the bundled Lottie ring deleted, or passed as `animation:`.
- [ ] Clean build with zero warnings; tests pass; run on an iPhone simulator and, for Mac apps, on Catalyst.
- [ ] Theme switcher, dark mode, Increase Contrast, and an accessibility text size checked on the app's main screens.

## Rule tables

Generated from `Scripts/migrate-1.0.rules` by `Scripts/migrate-1.0.sh . --print-table`; regenerate rather than edit. The "New" column of a dotted path shows the final name (after the type pass). Hand-edit patterns are Perl regular expressions.

### Products

| Old | New |
|---|---|
| `LumiKitNetwork` | `LumiKitDebug` |

### Dotted paths

| Old | New |
|---|---|
| `LMKThemeManager.shared.apply(` | `LMKTheme.apply(` |
| `LMKThemeManager.shared.reset()` | `LMKTheme.reset()` |
| `LMKThemeManager.shared.current` | `LMKTheme.current.colors` |
| `LMKThemeManager.shared.typography` | `LMKTheme.current.typography` |
| `LMKThemeManager.shared.spacing` | `LMKTheme.current.spacing` |
| `LMKThemeManager.shared.cornerRadius` | `LMKTheme.current.cornerRadius` |
| `LMKThemeManager.shared.shadow` | `LMKTheme.current.shadow` |
| `LMKThemeManager.shared.alpha` | `LMKTheme.current.alpha` |
| `LMKThemeManager.shared.layout` | `LMKTheme.current.layout` |
| `LMKThemeManager.shared.animation` | `LMKTheme.current.animation` |
| `LMKNetworkRequestRecord.LMKRequestData` | `LMKNetworkRequestRecord.Request` |
| `LMKNetworkRequestRecord.LMKResponseData` | `LMKNetworkRequestRecord.Response` |
| `LMKAlertPresenter.presentAlert(` | `LMKAlert.present(` |
| `LMKCountdownConfirmation.present(` | `LMKAlert.presentCountdownConfirmation(` |
| `LMKSceneUtil.getKeyWindow()` | `LMKScene.keyWindow` |
| `LMKImageUtil.getSFSymbolImage(` | `LMKImage.symbol(` |
| `LMKDominantColorExtractor.dominantColors(` | `LMKImage.dominantColors(` |
| `LMKDominantColorExtractor.dominantColor(` | `LMKImage.dominantColor(` |
| `LMKDominantColorExtractor.Strategy` | `LMKImage.DominantColorStrategy` |
| `LMKQRCodeGenerator.generateQRCode(` | `LMKImage.qrCode(` |
| `LMKQRCodeGenerator.CorrectionLevel` | `LMKImage.QRCorrectionLevel` |
| `LMKDateFormatterHelper.formatNumber(` | `LMKFormat.number(` |
| `LMKDateFormatterHelper.numberFormatter()` | `LMKFormat.numberFormatter()` |
| `LMKShareService.shareImage(` | `LMKShare.image(` |
| `LMKShareService.shareFile(` | `LMKShare.file(` |
| `LMKToast.showSuccessOnWindow(message:` | `LMKToast.show(.success,` |
| `LMKToast.showWarningOnWindow(message:` | `LMKToast.show(.warning,` |
| `LMKToast.showErrorOnWindow(message:` | `LMKToast.show(.error,` |
| `LMKToast.showInfoOnWindow(message:` | `LMKToast.show(.info,` |
| `LMKToast.showSuccess(message:` | `LMKToast.show(.success,` |
| `LMKToast.showWarning(message:` | `LMKToast.show(.warning,` |
| `LMKToast.showError(message:` | `LMKToast.show(.error,` |
| `LMKToast.showInfo(message:` | `LMKToast.show(.info,` |
| `LMKAlpha.overlayLight` | `LMKAlpha.xxs` |
| `LMKAlpha.overlayMedium` | `LMKAlpha.xs` |
| `LMKAlpha.overlayDark` | `LMKAlpha.small` |
| `LMKAlpha.semiTransparent` | `LMKAlpha.medium` |
| `LMKAlpha.overlayStrong` | `LMKAlpha.xl` |
| `LMKAlpha.overlayOpaque` | `LMKAlpha.xxl` |
| `LMKAlpha.dimmingOverlay` | `LMKAlpha.dimming` |
| `LMKAlpha.overlay` | `LMKAlpha.large` |
| `LMKShadow.cellCard()` | `LMKShadow.style(for: .level2)` |
| `LMKShadow.button()` | `LMKShadow.style(for: .level2)` |
| `LMKShadow.small()` | `LMKShadow.style(for: .level1)` |
| `LMKShadow.medium()` | `LMKShadow.style(for: .level4)` |
| `LMKShadow.large()` | `LMKShadow.style(for: .level5)` |
| `LMKShadow.card()` | `LMKShadow.style(for: .level3)` |
| `LMKShadow.opacity` | `LMKShadow.iconOverlayOpacity` |
| `LMKAnimationHelper.Duration.buttonPress` | `LMKAnimation.Duration.instant` |
| `LMKAnimationHelper.Duration.uiShort` | `LMKAnimation.Duration.fast` |
| `LMKAnimationHelper.Duration.photoLoad` | `LMKAnimation.Duration.fast` |
| `LMKAnimationHelper.Duration.actionSheet` | `LMKAnimation.Duration.normal` |
| `LMKAnimationHelper.Duration.alert` | `LMKAnimation.Duration.normal` |
| `LMKAnimationHelper.Duration.modalPresentation` | `LMKAnimation.Duration.moderate` |
| `LMKAnimationHelper.Duration.listInsertDelete` | `LMKAnimation.Duration.moderate` |
| `LMKAnimationHelper.Duration.listUpdate` | `LMKAnimation.Duration.moderate` |
| `LMKAnimationHelper.Duration.cardExpand` | `LMKAnimation.Duration.moderate` |
| `LMKAnimationHelper.Duration.screenTransition` | `LMKAnimation.Duration.slow` |
| `LMKAnimationHelper.Duration.errorShake` | `LMKAnimation.Duration.slow` |
| `LMKAnimationHelper.Duration.successFeedback` | `LMKAnimation.Duration.emphasis` |
| `LMKAnimationHelper.Spring.damping` | `LMKAnimation.spring.damping` |
| `LMKAnimationHelper.Curve.easeInOut` | `LMKAnimation.Curve.easeInOut.options` |
| `LMKAnimationHelper.Curve.easeOut` | `LMKAnimation.Curve.easeOut.options` |
| `LMKAnimationHelper.Curve.easeIn` | `LMKAnimation.Curve.easeIn.options` |
| `LMKColor.primaryDark` | `LMKColor.primaryVariant` |
| `LMKColor.imageBorder` | `LMKColor.outline` |
| `LMKColor.graySoft` | `LMKColor.fillStrong` |
| `LMKColor.grayMuted` | `LMKColor.fill` |
| `LMKColor.white` | `LMKColor.onAccent` |
| `LMKColor.black` | `LMKColor.scrim` |
| `LMKActionSheet.ActionStyle` | `LMKActionSheet.Action.Style` |
| `LMKGlassView.Style` | `LMKGlassView.Variant` |
| `LMKProgressViewController.Style` | `LMKProgressViewController.Mode` |
| `LMKSegmentedControl.CornerStyle` | `LMKSegmentedControl.Corners` |
| `lmkBadgeStrings` | `LMKBadgeView.strings` |
| `lmkCheckboxCellStrings` | `LMKCheckboxCell.strings` |
| `lmkPhotoCropStrings` | `LMKPhotoCropViewController.strings` |
| `LMKDateFormatterHelper.formatDate(` | `LMKDateFormat.string(` |
| `LMKFileUtil.generateTempFileURL(fileExtension:` | `LMKFile.temporaryURL(extension:` |
| `LMKFileUtil.clearTmpDirectory()` | `LMKFile.clearTemporaryFiles()` |

### Types

| Old | New |
|---|---|
| `LMKConcurrencyHelpers` | `LMKConcurrency` |
| `LMKDateFormatterHelper` | `LMKDateFormat` |
| `LMKDateHelper` | `LMKDate` |
| `LMKFormatHelper` | `LMKFormat` |
| `LMKFileUtil` | `LMKFile` |
| `LMKRequestData` | `LMKNetworkRequestRecord.Request` |
| `LMKResponseData` | `LMKNetworkRequestRecord.Response` |
| `LMKAlertPresenter` | `LMKAlert` |
| `LMKCountdownConfirmation` | `LMKAlert` |
| `LMKAnimationHelper` | `LMKAnimation` |
| `LMKHapticFeedbackHelper` | `LMKHaptics` |
| `LMKDeviceHelper` | `LMKDevice` |
| `LMKDeviceType` | `LMKDevice.Kind` |
| `LMKScreenSize` | `LMKDevice.ScreenSize` |
| `LMKSceneUtil` | `LMKScene` |
| `LMKImageUtil` | `LMKImage` |
| `LMKDominantColorExtractor` | `LMKImage` |
| `LMKQRCodeGenerator` | `LMKImage` |
| `LMKOverscrollFooterHelper` | `LMKOverscrollFooterView` |
| `LMKDatePickerHelper` | `LMKDatePicker` |
| `LMKThemeManager` | `LMKTheme` |
| `LMKTheme` | `LMKColorTheme` |
| `LMKDefaultTheme` | `LMKColorTheme` |
| `LMKShadowConfig` | `LMKShadowTheme.Shadow` |
| `LMKTypographyType` | `LMKTypography.Kind` |
| `LMKButtonRole` | `LMKButton.Role` |
| `LMKBottomSheetController` | `LMKBottomSheetViewController` |
| `LMKCardPageController` | `LMKCardPageViewController` |
| `LMKCardPanelController` | `LMKCardPanelViewController` |
| `LMKSegmentedPageController` | `LMKSegmentedPageViewController` |
| `LMKEnumSelectionBottomSheet` | `LMKEnumPicker` |
| `LMKBannerType` | `LMKStatus` |
| `LMKToastType` | `LMKStatus` |
| `LMKChipStyle` | `LMKChipView.Variant` |
| `LMKEmptyStateStyle` | `LMKEmptyStateView.Layout` |
| `LMKGradientDirection` | `LMKGradientView.Direction` |
| `LMKDividerOrientation` | `LMKDividerView.Orientation` |
| `LMKTipArrowDirection` | `LMKTipView.ArrowDirection` |
| `LMKTipStyle` | `LMKTipView.Placement` |
| `LMKTextFieldState` | `LMKValidationState` |
| `LMKBadgeStrings` | `LMKBadgeView.Strings` |
| `LMKCheckboxCellStrings` | `LMKCheckboxCell.Strings` |
| `LMKShareService` | `LMKShare` |
| `LMKPhotoEXIFService` | `LMKPhotoMetadata` |
| `LMKPhotoGridContentMode` | `LMKPhotoGridViewController.ContentMode` |
| `LMKPhotoGridSortOrder` | `LMKPhotoGridViewController.SortOrder` |
| `LMKPhotoBrowserStrings` | `LMKPhotoBrowserViewController.Strings` |
| `LMKPhotoGridStrings` | `LMKPhotoGridViewController.Strings` |
| `LMKPhotoCropStrings` | `LMKPhotoCropViewController.Strings` |
| `LMKSharePreviewStrings` | `LMKSharePreviewViewController.Strings` |

### Call shapes (Perl regex, applied after the type pass)

| Pattern | Replacement |
|---|---|
| `((?:LMKErrorHandler\|LMKAlert\|LMKActionSheet\|LMKEnumPicker\|LMKDatePicker)\.present\w*\(\s*)on:` | `${1}from:` |
| `((?:LMKErrorHandler\|LMKAlert\|LMKActionSheet\|LMKEnumPicker\|LMKDatePicker)\.present\w*\(\s*)in:` | `${1}from:` |
| `(LMKToast\.show\([^\n]*?)\bon:` | `${1}in:` |
| `(LMKTip\.show\([^\n]*?)\bstyle:` | `${1}placement:` |
| `(LMKTip\.show\([^\n]*?)\bon:` | `${1}in:` |
| `\bonShowComplete:` | `completion:` |
| `\.show\(on:` | `.show(in:` |
| `\.showOnWindow\(` | `.show(` |
| `\btapHandler:` | `onTap:` |
| `LMKToast\.show\(type:\s*(\.\w+),\s*message:` | `LMKToast.show($1,` |
| `LMKToastView\(type:` | `LMKToastView(status:` |
| `LMKBannerView\(type:` | `LMKBannerView(status:` |
| `\.(filled\|outlined\|ghost\|iconOnly)\(LMKColor\.primary\)` | `.${1}(.primary)` |
| `\.(filled\|outlined\|ghost\|iconOnly)\(LMKColor\.secondary\)` | `.${1}(.secondary)` |
| `\.(filled\|outlined\|ghost\|iconOnly)\(LMKColor\.tertiary\)` | `.${1}(.tertiary)` |
| `\.(filled\|outlined\|ghost\|iconOnly)\(LMKColor\.error\)` | `.${1}(.destructive)` |
| `\.(filled\|outlined\|ghost\|iconOnly)\(LMKColor\.warning\)` | `.${1}(.warning)` |
| `\.(filled\|outlined\|ghost\|iconOnly)\(LMKColor\.success\)` | `.${1}(.success)` |
| `\.(filled\|outlined\|ghost\|iconOnly)\(LMKColor\.info\)` | `.${1}(.info)` |
| `\.(filled\|outlined\|ghost\|iconOnly)\(LMKColor\.textSecondary\)` | `.${1}(.neutral)` |
| `\.(filled\|outlined\|ghost\|iconOnly)\(LMKColor\.textPrimary\)` | `.${1}(.neutral)` |
| `LMKButtonFactory\.(filled\|outlined\|ghost)\(\s*role:\s*(\.\w+),\s*title:\s*("[^"]*"\|[\w.()]+),` | `LMKButton(title: $3, style: .${1}(${2}),` |
| `LMKButtonFactory\.iconOnly\(\s*role:\s*(\.\w+),\s*iconName:\s*("[^"]*"\|[\w.()]+),` | `LMKButton(systemImage: $2, style: .iconOnly(${1}),` |
| `LMKLabelFactory\.(body\|bodyMedium\|bodyBold\|subbodyMedium\|caption\|captionMedium\|small\|smallMedium)\(text:` | `UILabel.lmk_make(.${1}, text:` |
| `LMKCardFactory\.elevatedCardView\(\)` | `LMKCardView(style: .elevated)` |
| `LMKCardFactory\.flatCardView\(\)` | `LMKCardView(style: .flat)` |
| `LMKCardFactory\.cardView\(\)` | `LMKCardView(style: .cell)` |
| `\.lmk_pointInside\(` | `.lmk_point(inside:` |
| `(LMKProgressViewController\([^\n]*?)\bstyle:` | `${1}mode:` |
| `\.cornerStyle = \.(pill\|rounded)\b` | `.style.corners = .${1}` |
| `\.pinToTop\(of:` | `.install(in:` |
| `LMKPhotoCropViewController\(image:\s*([^,)]+),\s*delegate:\s*[^)]+\)` | `LMKPhotoCropViewController(image: $1)` |
| `LMKLabelFactory\s*\.heading\(text:\s*("[^"]*"\|[^,)]+?),\s*level:\s*([1-4])\)` | `UILabel.lmk_make(.h$2, text: $1)` |
| `LMKLabelFactory\s*\.heading\(text:\s*` | `UILabel.lmk_make(.h1, text:` |
| `LMKLabelFactory\s*\.scientificName\(text:\s*` | `UILabel.lmk_make(.italicBody, text:` |
| `LMKLabelFactory\s*\.(caption\|body\|small\|bodyMedium\|bodyBold\|subbodyMedium\|extraSmall)\(\s*text:` | `UILabel.lmk_make(.$1, text:` |
| `(?<!try\? )(?<!try )\bLMKConcurrency\.(encode\|decode)\(` | `try? LMKConcurrency.$1(` |

### Members (type-blind)

| Old | New |
|---|---|
| `tapHandler` | `onTap` |
| `actionHandler` | `onAction` |
| `dismissHandler` | `onDismiss` |
| `valueChangedHandler` | `onValueChange` |
| `stateChangedHandler` | `onValueChange` |
| `textChangedHandler` | `onTextChange` |
| `pageChangedHandler` | `onPageChange` |
| `multiSelectionChangedHandler` | `onSelectionChange` |
| `selectionChangedHandler` | `onSelectionChange` |
| `backAction` | `onBack` |
| `isChipSelected` | `isSelected` |
| `dismissSheet()` | `dismiss()` |
| `dismissPanel(` | `dismiss(` |
| `photoBrowserStrings` | `browserStrings` |
| `lmk_singleLineShrinkToFit(` | `shrinkingTitleToFit(` |
| `lmk_touchAreaEdgeInsets` | `lmk_hitTestInsets` |
| `enableNetworkLogging()` | `lmk_enableNetworkLogging()` |
| `nonEmpty` | `lmk_nonEmpty` |
| `[safe:` | `[lmk_safe:` |

### File-conditional (only in files matching the precondition)

| Precondition | Pattern and replacement |
|---|---|
| `LMKEnumSelectable` | `var iconName: String \{` to `var iconName: String? {` |

### Hand edits (reported by file and line, never rewritten)

| Pattern | Recipe |
|---|---|
| `\bLMKTheme\.apply\(` | Theme registration: pass a LMKTheme value. Convert `struct XTheme: LMKColorTheme { … }` into `extension LMKTheme { static let x = LMKTheme(colors: LMKColorTheme(primary: …)) }` and call `LMKTheme.apply(.x)`; only the colors that differ from the defaults need arguments. |
| `:\s*LMKColorTheme\s*\{` | LMKColorTheme is a struct now: replace the conformance with `extension LMKTheme { static let x = LMKTheme(colors: LMKColorTheme(…)) }` (see the theme recipe in docs/MIGRATION-1.0.md). |
| `LMKTheme\.apply\(\s*(colors\|typography\|spacing\|cornerRadius\|shadow\|alpha\|layout\|animation\|badge):` | reshape: per-category `apply(spacing: x)` became `LMKTheme.update { $0.spacing = x }` (reads: `LMKTheme.current.spacing`). |
| `\bLMKTheme(?:\.shared)?\.configure\(` | remove: `configure(colors:…)` is gone; build one `LMKTheme(colors:typography:spacing:…)` value and call `LMKTheme.apply(_:)`. |
| `\bLMKTheme\.shared\b(?!\.configure\()` | remove: `LMKThemeManager.shared` is gone; the theme is static API on `LMKTheme` (`LMKTheme.current.spacing`, `LMKTheme.current.badge` for the badge metrics, `LMKTheme.apply(_:)` and `LMKTheme.update { … }` to change it), so a stored manager reference goes away. |
| `LMKColor\.(onAccent\|scrim)\b` | Review: `white` became `onAccent` (text on a filled accent) and `black` became `scrim` (dimming). Use literal `.white` / `.black` where the old token meant the actual color (forced-dark chrome, `layer.shadowColor`). |
| `LMKColor\.photoBrowserBackground` | remove: set `LMKPhotoBrowserViewController.Style.backgroundColor` (per instance or `theme.photoBrowser`) instead. |
| `\.addAsChild\(` | remove: `LMKBottomSheetViewController.addAsChild(sheet, in: host)` became the instance method `sheet.present(from: host)`. |
| `LMKCardPanelViewController\.show\(` | remove: `LMKCardPanelViewController.show(panel, in:)` became `panel.present(from: hostViewController)`. |
| `LMKSearchBarDelegate\|lmkSearchBar\w*\(` | remove: the search-bar delegate is gone; set `onTextChange`, `onSearch`, `onBeginEditing`, `onEndEditing`, `onCancel` closures on the bar instead. |
| `LMKPhotoCropDelegate\|photoCropViewController\w*\(` | remove: the crop delegate is gone; set `onCrop` / `onCancel` on `LMKPhotoCropViewController`. |
| `LMKSharePreviewDelegate\|sharePreview\w*\(` | remove: the share-preview delegate is gone; set `onShare` / `onSave` / `onFailure` on `LMKSharePreviewViewController`. |
| `\.configure\(count:\|(?m:\.configure\(text:\s*[^,)]*\)[ \t]*$)\|badge\.configure\(\)` | reshape (LMKBadgeView only): `configure(count: n)` became `configure(.count(n))`, `configure(text: s)` became `configure(.text(s))`, the dot badge is `configure(.dot)`. |
| `\.(badgeColor\|borderColor)\s*=\|LMKDividerView\.defaultThickness\|\.thickness\s*=` | reshape: badge and divider colors/thickness are `style` fields (`badge.style.surface.background = .solid(c)`, `divider.style.thickness = t`). |
| `LMKLoadingStateView\([^)]*overlayStyle:` | reshape: `LMKLoadingStateView(overlayStyle: true)` became `LMKLoadingStateView(style: .overlay)`. |
| `\.configure\(message:\|LMKEmptyStateView\.(inlineCellHeight\|cardCellHeight\|fullScreenCellHeight\|inlineHorizontalInsets)` | reshape: `configure(message:icon:style:action:)` became `configure(LMKEmptyStateView.Content(title:message:icon: .system("name"), primaryAction:))` with the layout in `style.layout`; size the row yourself. |
| `LMKGlassView\.makeContainer\(` | Review: `makeContainer` now returns `LMKGlassContainerView` (typed; `spacing` is settable). |
| `LMKFloatingButton\.current\|LMKFloatingButton\.dismissCurrent\(\|\.showBadge\(\|\.hideBadge\(` | reshape: the floating button has no global; keep the instance from `LMKFloatingButton.show(icon:in:onTap:)` (or `button.show(in:)`), call `dismiss()` on it, and set `badge = .count(n)` / `.dot` / `nil`. |
| `LMKTip\.show\([^)]*\n[^)]*\b(style\|on):` | Review: multi-line tip call still passes `style:` / `on:`; rename to `placement:` / `in:`. |
| `\.expandsActiveDot\s*=\|\.maxVisibleDots\s*=` | Review (LMKPageIndicator): `expandsActiveDot` still works as a property (it writes `style.expandsActiveDot`); dot sizes and colors are `style` fields. |
| `\.showsCancelButton\s*=` | reshape (LMKSearchBar): `showsCancelButton` is read-only; set `cancelButtonMode = .always \| .never \| .automatic`. |
| `LMKTextView\(\)[^\n]*\n?[^\n]*\.minimumHeight\s*=\s*\d` | Review (LMKTextView): `minimumHeight` is now optional (`CGFloat?`); `maximumHeight` caps growth. |
| `\.chipColor\b` | reshape: `chipColor` became `style.tintColor` (`chip.style = .filled.tint(color)` or `chip.style.tintColor = color`). |
| `\.(cardBackgroundColor\|cardCornerRadius)\b\|LMKCardView\(\)\.contentInsets\|card\.contentInsets\s*=` | reshape: card appearance is `style.surface` (`card.style.surface.background = .solid(c)`, `.corners = .fixed(r)`, `.contentInsets = …`). |
| `LMKStatus\.\w+\.iconName\|status\.iconName\|type\.iconName` | reshape: `LMKStatus.iconName` became `systemImageName: String?` (`.neutral` has none). |
| `LMKToastView\.defaultDuration\|\.showOnWindow\(` | reshape: `LMKToast.defaultDuration`; window presentation is `LMKToast.show(.status, message)` with no `in:` (or `presentation: .inWindowScene(nil)`). |
| `\.didTapHandler\b` | remove: `didTapHandler` is gone; use `onTap` and capture the button. |
| `\.applyStyle\(\|\.applyIconStyle\(` | remove: `applyStyle(.filled(c), title: t)` became `button.style = .filled(.role); button.title = t`; `applyIconStyle` became `button.style = .iconOnly(); button.setSymbol("name")`. |
| `\.configuration\?\.(title\|image\|imagePlacement\|imagePadding\|contentInsets)\s*=` | Review: LMKButton now exposes `title`, `image`, `setSymbol(_:)`, and `style.imagePlacement` / `style.imagePadding` / `style.surface.contentInsets`; keep `configuration?` only on plain UIButtons. |
| `LMKButtonFactory\|LMKLabelFactory\|LMKCardFactory` | remove: the factories are gone; `LMKButton(title:style:)`, `UILabel.lmk_make(_:text:color:)`, `LMKCardView(style:)` (add subviews to `contentView`). |
| `LMKLabelFactory\.heading\(` | remove: `heading(text:level:)` became `UILabel.lmk_make(.h1\|.h2\|.h3\|.h4, text:)`. |
| `\bLMKToggleButton\b\|ToggleState\|lmkToggleButtonStrings` | remove: LMKToggleButton is gone; use `LMKButton` with `isToggle = true`, `selectedTitle` / `selectedImage`, and `onValueChange`. |
| `LMKKeyboardInsetHelper\|LMKKeyboardObserver` | remove: use `scrollView.lmk_enableKeyboardAdjustment()` / `lmk_disableKeyboardAdjustment()`. |
| `\.lmk_fadeIn\(\|\.lmk_fadeOut\(` | remove: `view.lmk_fadeIn(…)` became `LMKAnimation.fadeIn(view, …)` (same for fadeOut). |
| `lmk_safeAreaSnp\|lmk_setEdgesEqualToSuperview\|lmk_centerInSuperview\|lmk_setAutoLayoutSize` | remove: write the SnapKit constraints directly (`safeAreaLayoutGuide.snp`, `edges.equalToSuperview()`, `center.equalToSuperview()`). |
| `lmk_configureCellHighlight\(` | remove: call `cell.lmk_configureCustomHighlight()` on the cell. |
| `lmk_animatePress\(` | remove: use `LMKButton` (press animation built in) or `LMKAnimation.animateButtonPress(_:)`. |
| `lmk_configureIconListRow\(` | remove: became `cell.lmk_applyListRow(LMKListRowConfiguration(title:) …)`; see the list-row recipe. |
| `lmk_emptyStateCell\(` | remove: host the `LMKEmptyStateView` yourself (`wrappedForTableBackground`) and size the row. |
| `LMKPhotoMetadata\.(extractDate\|extractLocation)\(` | remove: `await LMKPhotoMetadata.read(from: pickerResult).date` / `.coordinate`; pass raw `Data`, never a decoded `UIImage`. |
| `LMKDateFormat\.(dateFormatter\|configure)\(` | remove: `LMKDateFormat.string(date, date: .medium, time: .none)`; a user-chosen pattern goes through `LMKDateFormat.preferredDatePattern`. |
| `\.presentMultiSelect\(` | remove: `LMKEnumPicker.present(from:title:options:selection:onSelect:)` with a `Set<T>` selection (multi-select is chosen by the selection type). |
| `LMKLayout\.(searchBarHeight\|searchBarIconSize\|clearButtonSize)\b` | Review: the search-bar metrics moved to `LMKSearchBar.Style` (`height`, `iconSize`, `clearButtonSize`). |
| `\bLMKBadge\.\|\bLMKBadgeTheme\b` | remove: badge metrics live on `LMKBadgeView.Style` (app-wide via `theme.badge`). |
| `LMKBottomSheetLayout\|LMKCardPageLayout\|LMKCardPanelLayout\|LMKTipLayout\|LMKFloatingButtonLayout\|LMKPhotoBrowserConfig` | remove: the constant bags are gone; themeable values are `Style` fields on the owning component. |
| `override (open \|public )?var (headerHeight\|showsLeadingButton\|showsTrailingButton\|showsHeaderSeparator\|trailingButtonSymbol\|leadingButtonSymbol\|cardMaxWidth\|cardHorizontalInset\|cardMaxHeightRatio\|dismissesOnBackgroundTap\|stackSpacing\|contentInsets\|keyboardDismissMode\|alwaysBounceVertical\|scrollViewUseSafeArea\|edgePanBandWidth\|commitVelocityThreshold)\b` | Review: appearance overrides on the base controllers became `Style` fields (`style.headerHeight = …` in `init`; `cardMaxHeightRatio` is `LMKCardPanelViewController.Style.heightRatio`, an exact height fraction); `dismissesOnBackgroundTap` is an instance property. |
| `override (open \|public )?func (dismissSheet\|dismissPanel\|onDismissTapped)\b` | Review: `dismiss()` is the single dismissal; `onDismissTapped()` became `onDismiss: ((DismissReason) -> Void)?`. |
| `\.(selectedIndex\|setSelectedIndex\(\|selectedIndices\|setSelectedIndices\(\|allowsMultipleSelection)\b` | Review (LMKFilterChipBar only): selection is one `selection: Set<Int>` with `setSelection(_:animated:)`, `selectionMode`, and `onSelectionChange: (Set<Int>) -> Void`. |
| `\.(fitsSegmentsToContent\|isScrollable\|scrollableItemPadding\|itemSpacing\|makeScrollableContainer\|itemPadding)\b` | Review (LMKSegmentedControl only): the layout knobs became `style.layout = .equalWidth \| .fitContent \| .scrollable(padding:spacing:)` and `itemPadding` moved to `style.itemPadding`; the control owns its scroll view. |
| `\bLMKButton\.Style\b.*=\s*\.(filled\|outlined\|ghost\|iconOnly)\((?!\.)` | Review: `LMKButton.Style` presets take a role (`.filled(.primary)`), not a color; use `.tint(_:)` for a custom color. |
| `\blmk_hitTestInsets\s*=` | Review: has no effect unless the owner overrides `point(inside:with:)` and calls `lmk_point(inside:with:)`; LumiKit controls enforce 44pt targets themselves, so delete dead assignments. |
| `subscript\(safe\|var nonEmpty\b` | Review: a local declaration collides with LumiKit's `[lmk_safe:]` / `lmk_nonEmpty`; delete the copy or rename it. |
| `\bLMKLocaleHelper\b` | Review: the `LMK` prefix is reserved for LumiKit; rename the app's helper. |
| `(LMKAlert\|LMKErrorHandler\|LMKActionSheet\|LMKEnumPicker\|LMKDatePicker)\.\w+\([^)]*\n\s*on:` | Review: multi-line call still passes `on:`; rename the label to `from:`. |
| `LMKToast\.show\([^)]*\n\s*on:` | Review: multi-line toast call still passes `on:`; rename the label to `in:`. |
| `\.(barBackgroundColor\|largeTitleFont\|largeTitleColor\|inlineTitleFont\|inlineTitleColor\|buttonTintColor)\b` | Review (LMKNavigationBar only): appearance moved to `style` (`surface.background`, `tintColor`, `titleTextStyle` / `titleColor`, `largeTitleTextStyle` / `largeTitleColor`). |
| `\.set(Left\|Right)ItemEnabled\(at:` | remove: give the item an `identifier` and call `updateItem("id") { $0.isEnabled = ... }`. |
| `\.showsSeparator\s*=` | Review (LMKNavigationBar only): `showsSeparator` is a Style field (`style.showsSeparator`). |
| `override (open \|public )?func refreshSheetColors\b` | Review: `refreshSheetColors()` is gone; override `applyTheme(_:)` (call `super`) and use `style` fields. |
| `\bsuper\.init\(cancelTitle:` | Review: `LMKBottomSheetViewController.init(cancelTitle:)` became `init(style:)`; set `strings.cancel` per instance for a custom title. |
| `\bcontainerBottomConstraint\b` | remove: the constraint is internal; use `additionalBottomInset` for a manual lift (the keyboard lift is built in). |
| `\bLMKActionSheet\(` | remove: build an `LMKActionSheet.Configuration` and call `LMKActionSheet.present(_:from:)` (the class is `LMKActionSheetViewController`). |
| `\bcontentHeight:` | Review (LMKActionSheet): custom content is self-sizing; drop `contentHeight:` and give the view an intrinsic size or constraints. |
| `LMKActionSheet\.present\([^)]*\bonDismiss:` | Review: the action sheet reports cancellation through `Configuration.onCancel` (or the sheet's `onDismiss(reason)`). |
| `\bcurrentSelection:` | Review (LMKEnumPicker): `present(from:title:options:selection:onSelect:)`; a `T?` selection is single-select, a `Set<T>` is multi-select; `showIcons:` became `showsIcons:` (default on). |
| `var iconName: String \{` | Review (LMKEnumSelectable): `iconName` is `String?` with a default of `nil`; change the type or delete the property. |
| `LMKDatePicker\.present(DatePickerAlert\|DatePicker\|FutureDatePicker\|PastDatePicker\|DateRangePicker\|CalendarRangePicker\|DatePickerWithTextField)\(` | Review: `LMKDatePicker.present(_ configuration:from:onConfirm:)` with `Configuration(...)`, `.past(...)`, `.future(...)`; ranges via `presentRange` / `presentCalendarRange`; notes via `presentWithTextField`. |
| `override (open \|public )?(var\|func) (leadingButtonSymbol\|trailingButtonSymbol\|showsLeadingButton\|showsTrailingButton\|showsHeaderSeparator\|refreshCardPageColors\|trailingButtonTapped)\b` | Review (LMKCardPageViewController): set `leadingItem` / `trailingItem` (`LMKNavigationBarItem`) and `style.showsHeaderSeparator` in `init`; `applyTheme(_:)` replaces the color refresh. |
| `override (open \|public )?var dismissesOnBackgroundTap\b` | Review (LMKCardPanelViewController): `dismissesOnBackgroundTap` is an instance property now. |
| `override (open \|public )?func installSegmentedControl\b` | Review (LMKSegmentedPageViewController): set `segmentedControlPlacement = .container(slot)` (build the slot before `super.viewDidLoad()`) or `.manual`. |
| `LMKOverscrollFooterView\(footerView:` | remove: `LMKOverscrollFooterView(contentView:height:)` + `attach(to: scrollView)`; it follows the scroll view itself (drop `updatePosition()` calls and the `overscrollProgress` alpha plumbing). |
| `presentActionSheet\([^)]*actions: \[\(` | Review (LMKAlert): actions are `[LMKAlert.Action]` (title, image, style, isEnabled, handler); pass `anchor:` for the iPad popover. |
| `presentTextInput\([^)]*\b(autocapitalizationType\|autocorrectionType\|keyboardType\|configureField\|saveTitle\|cancelTitle):` | Review (LMKAlert): the long form became `presentTextInput(LMKAlert.TextInput(...), from:onSave:)` (adds `isSecure` and `validate`). |
| `LMKFormScaffold\.install\([^)]*contentInsets: UIEdgeInsets` | Review: `contentInsets` is `NSDirectionalEdgeInsets` now; `widthMode:` adds `.readable` / `.capped`. |
| `\.setSubtitle\(` | Review (LMKProgressViewController): `subtitle` is a property; `setState(_:message:)` covers terminal states. |
| `\bDateFormatters\.\|\bTripDateFormatting\.(rangeLabel\|residenceLabel\|timeLabel\|dayTimeLabel\|usesTwelveHourClock\|widestClockSample\|dayLabel\|dayLabelWithYear\|stripWeekday\|stripDayNumber)\b` | Review: the app-local date formatter cache is `LMKDateFormat` now (`string(_:date:time:context:)`, `rangeLabel`, `residenceLabel`, `relativeDayString`, `clockTime`, `dateWithClockTime`, `widestClockSample`, `usesTwelveHourClock`, `weekdaySymbols`; a stored time zone or the in-app time format goes through `Context`). |
| `\bMacWindowConfig\b` | remove: `LMKScene.configureMacWindow(for:minimumSize:maximumSize:hidesTitleBar:)` from `scene(_:willConnectTo:options:)` (a no-op off Catalyst). |
| `\bfunc formKeyCommands\(\|\bformKeyCommands\(save:` | Review: `lmk_formKeyCommands(save:cancel:)` (LumiKit) replaces the app copy; Escape defaults to dismissing. |
| `UIScreen\.main\.scale` | Review: `view.lmk_displayScale` (or `LMKScene.screenScale` without a view) and `LMKImage.pixelSize(points:scale:)` for pixel-sized image requests. |
| `CGImageSourceCreateThumbnailAtIndex` | Review: `LMKImage.downsample(data:maxPixelSize:)` / `downsample(fileURL:maxPixelSize:)` (sync and async) and `downsampledJPEG(data:maxPixelSize:quality:)` cover the ImageIO thumbnail path. |
| `\bembedEXIF\(` | remove: `LMKPhotoMetadata.write(date:coordinate:to:)` (Data or file URL). |
| `\b(pinFormContent\|pinListHorizontally)\(` | Review: `content.lmk_pinReadableWidth(in:)` (or `view.lmk_readableWidthGuide`) with `LMKLayout.readableContentMaxWidth` as the cap. |
| `\b(applyDisclosureIndicator\|removeDisclosureIndicator\|installRowPointerInteraction\|applyListTextStyle\|applyThumbnail\|applyIcon)\(\|\bListTableFactory\b` | Review: list rows are `LMKListRowConfiguration` + `cell.lmk_applyListRow(_:)`; rows that stay on `UIListContentConfiguration` use `lmk_applyTextStyle`, `lmk_applyLeadingSymbol`, `lmk_applyThumbnail`, and `lmk_installRowPointerInteraction`; tables come from `LMKListTable.makeInsetGrouped`. |
| `\b(PFListCell\|PFActionTile\|TDActionTile\|TDStarRatingView\|PFCopyableLabel\|PFPhotoButton\|TDCheckboxButton)\b` | Review: the app component has a LumiKit counterpart (`LMKListRowConfiguration`, `LMKActionTile`, `LMKRatingControl`, `LMKCopyableLabel`, `LMKPhotoButton`, `LMKCheckbox`); adopt it and delete the copy. |
| `\btripAccentGlyphTint\(` | Review: `UIColor.lmk_glyphTint(onLightAccentDarkenBy:)`; `LMKActionTile.accentColor` applies it itself. |
| `\b(TDMonthCalendarView\|TDCalendarDayCell\|MonthlyCalendarView\|CalendarMonthViewController\|CalendarDayCell)\b` | Review: the app month grid has a LumiKit counterpart: `LMKMonthCalendarView` (+ `LMKCalendarDayCell`, `LMKCalendarDayDecoration`) over Core `LMKCalendarDay` / `LMKCalendarMonth` / `LMKCalendarSelection`; keep the host's month and selection state and feed it through `configure(month:today:selection:decorations:)`. |
| `\b(dayKey\(for:\|Day\.dayKey\|localTodayKey\()` | Review: `LMKCalendarDay.key` ("yyyy-MM-dd") and `LMKCalendarDay.today(calendar:)` replace the app day-key helpers. |
| `\bCalendarLayout\.(headerHeight\|weekdayRowHeight\|dayCellSide\|dayCircleRadius\|dotSize\|dotSpacing\|maxDots\|dayLabelCenterOffset)\b` | Review: calendar metrics are `LMKMonthCalendarView.Style` fields (`headerHeight`, `weekdayRowHeight`, `dayRowHeight`, `circleRadius`, `dotSize`, `dotSpacing`, `maxDots`, `numeralCenterOffset`). |
| `\b(SortMenuView\|SortMenuPresenter)\b` | remove: `LMKSortMenu.makeMenu(sortOptions:layoutOptions:state:onSelectSort:onSelectLayout:)` on a `UIMenu`, anchored with `makeBarButtonItem(menu:)`, `makeNavigationBarItem(menu:)`, or `makeButton(menu:)`. |
| `\bPFAppearanceConfigurator\b` | remove: `LMKTabBarAppearance.applyGlobally(_:)` (or adopt `LMKTabBarController`, which applies `theme.tabBar` itself). |
| `\bclass \w+: UITabBarController\b` | Review: `LMKTabBarController(tabs:style:navigationControllerFactory:)` with `LMKTab`s covers lazy roots, `selectTab(identifier:)`, `reorderTabs(identifiers:)`, badges, ⌘1…N, and the iOS 26 minimize behavior / bottom accessory. |
| `\b(CardDetailViewController\|DetailCardBuilder\|DetailCardHelper\|DetailCardContext\|PFItemDetailViewController)\b` | Review: the detail chrome is `LMKDetailPageViewController` + `LMKDetailCard` rows rendered by `LMKDetailCardView`; keep pickers and forms app-side, replace label-reference patching with `setValue(_:forRowID:)` / `update(rowID:_:)`. |
| `\b(buildPropertyRow\|createInfoRow\|makeStatRow\|addRow\(label:\|addLinkRow\(\|makeLinkRow\|makeRatingRow\|makeExpensesRow\|makeSpotRow)\(` | Review: these are `LMKDetailCard.Row` kinds (`keyValue`, `link`, `rating`, `navigation`). |
| `LMKPhotoPickCropCoordinator\([^)]*\bsave:` | Review (LMKPhotoPickCropCoordinator): `save` is `(UIImage, LMKPhotoMetadata) async -> String?` (the picked bytes' capture date and location come along), `onFailure` receives a `Failure`, and `onCancel` reports a dismissed picker or crop. |
| `\.(updatePullProgress\|handleEndDragging)\(scrollView:` | Review (LMKLottieRefreshControl): `install(on:style:onRefresh:)` tracks the scroll view itself; delete the manual `scrollViewDidScroll` / `scrollViewDidEndDragging` calls. |
| `LMKLottieRefreshControl\(\)` | Review: `LMKLottieRefreshControl.install(on:style:onRefresh:)` returns nil under the Mac idiom (drop the `userInterfaceIdiom` guard) and pairs with `makeRefreshKeyCommand(action:)` for Command-R; the control plays the package's tinted ring unless `animation:` is passed. |
| `LMKLottieRefreshControl\.pullThreshold` | remove: `LMKLottieRefreshControl.Style.pullThreshold` (per instance or `theme.lottieRefreshControl`), defaulting to `LMKLayout.pullThreshold`. |
| `\.(animationBundle\|animationName)\s*=` | remove: pass `animation: LottieAnimation.named("file", bundle: .main)` to `LMKLottieRefreshControl(animation:style:)` or `install(on:animation:)`. |
| `\brefresh_spinner\b` | Review: LumiKitLottie bundles its own ring animation tinted from `theme.lottieRefreshControl`; delete the app copy unless it is passed as a custom `animation:`. |
| `LMKNetworkLogger\.configure\(maxRecords:` | Review (optional): `LMKNetworkLogger.configure(Configuration(maxRecords:redactedHeaderFields:hostFilter:))` adds credential redaction (on by default) and a host allowlist; the `maxRecords:` form still works. |
| `\.photoIsLivePhoto\(at:\|\.photoGridIsLivePhoto\(at:` | Review: unchanged, but `LMKPhotoGridDataSource` gained optional `photoGridPrefetch(indices:)` / `photoGridCancelPrefetch(indices:)` for image caches. |
| `LMKPhotoBrowserViewController\([^)]*\)\n[^\n]*\n[^\n]*modalPresentationStyle` | Review (LMKPhotoBrowserViewController): the browser presents over the full screen by default (`.overFullScreen`, so a dismiss drag shows the presenter through the fading stage; drop a `.fullScreen` assignment unless the presenter must leave the hierarchy, and refresh from `onDismiss` rather than the presenter's `viewWillAppear`) and a photo zooms out of `zoomSourceView`; `onDismiss` joins the delegate; `style` / `theme.photoBrowser` replace the fixed chrome. |
| `LMKListRowConfiguration\(` | Review (optional): list row titles and subtitles now wrap by default (as `UIListContentConfiguration`); pass `Style(titleLines: 1, subtitleLines: 1)` to keep a single-line row. |
| `LMKPageIndicator\.Strings\(` | Review: `Strings` gained `accessibilityLabel` as its first parameter; use labels (`Strings(pageFormat:)`) rather than positional arguments. |
| `UIBarButtonItem\((image\|title):[^)]*primaryAction:` | Review (optional): `LMKNavigationBarItem.makeBarButtonItem()` and `UINavigationItem.lmk_setItems(leading:trailing:)` bridge kit items to the system bar with the iOS 26 prominent style, badges, and transition identifiers. |
| `navigationItem\.titleView\s*=` | Review (optional): `UINavigationItem.lmk_setSubtitle(_:)` gives the system bar a subtitle (`subtitle` on iOS 26, a two-line title view before). |
| `viewWillTransition\(to:` | Review (optional): `LMKScene.observeGeometry(of:onChange:)` / `LMKDevice.observeScreenSize(of:onChange:)` report window resizes, folds, and the iOS 26 interactive-resize flag without a transition override. |
| `semanticContentAttribute\s*=\s*\.forceRightToLeft` | Review (optional): `lmk_forceLayoutDirection(.rightToLeft)` also flips natural text alignment on iOS 26 for RTL previews. |
| `lmk_make\(\.italicBody, text:` | Review: `scientificName(text:)` used `LMKColor.info`; pass `color: LMKColor.info` after the text to keep it. |
| `LMKConcurrency\.(encode\|decode)\(` | Review: `encode` / `decode` throw now (the script prefixed `try?` to keep the optional result); drop the `try?` where a thrown error is more useful, and pass `encoder:` / `decoder:` for custom strategies. |
| `LMKFile\.temporaryURL\(` | Review: `temporaryURL(extension:)` returns a non-optional `URL`; drop the `if let` / `guard let`. |
| `LMKLogger\.logStore\?\.entries\|\.formattedMessage\|LMKLogEntry\b` | Review (optional): `LMKLogEntry.message` is the raw message now (the call site is in `file` / `function` / `line`, `formattedMessage` joins them); the store's `formatted()` output is unchanged. |
| `LMKURLValidator\.validateHTTPSURL\(` | Review (optional): `validate(_:maxLength:requiredScheme:)` returns `Result<URL, ValidationError>` with the rejection reason; `validateHTTPSURL` still returns the trimmed string or nil. |
| `\.trimmingCharacters\(in: \.whitespacesAndNewlines\)[^\n]*isEmpty` | Review (optional): `lmk_trimmedOrNil` trims and returns nil for a blank string. |
| `LMKImage\.encodeJPEG\([^)]*\bmaxDimension:` | reshape: `encodeJPEG(_:maxDimension:quality:)` became `encodeJPEG(_:maxPixelSize:quality:)`, and the cap is in pixels of the image (points times `scale`), like `downsample`; rename the label and pass a pixel size (a value that was in points is multiplied by the display scale). |
| `LMKShare\.file\(` | Review: `LMKShare.file(at:)` keeps the file after sharing (0.x `shareFile` always deleted it); pass `deletesAfterShare: true` for a temporary export, which is then removed on cancel too. |
| `\.onToggle\s*=` | reshape (LMKCheckboxCell only): `onToggle: () -> Void` became `onValueChange: (Bool) -> Void` carrying the new `isDone` (the cell flips itself first, so `{ [weak self] in … }` becomes `{ [weak self] isDone in … }`); `setDone(_:animated:)` changes the row silently. |
| `\.onTextChange\s*=` | Review (LMKTextField / LMKTextView): `onTextChange` (0.x `textChangedHandler`) carries `String`, not `String?`; drop the `?? ""` and the optional binding on the payload. `LMKSearchBar.onTextChange` is unchanged. |
| `(?<!func )\b(animateIn\(\)\|animateOut\(velocity:)` | Review (LMKBottomSheetViewController / LMKCardPanelViewController subclasses): `animateIn()` / `animateOut(velocity:completion:)` are internal on `LMKBottomSheetViewController` and `LMKCardPanelViewController`; `present(from:)` slides in and `dismiss(reason:completion:)` (the panel: `dismiss(completion:)`) slides out. |
| `\.(numberOfPhotos\b\|photoDate\(at:\|photoSubtitle\(at:\|photoIsLivePhoto\(at:\|photoLivePhoto\(at:)` | Review (LMKPhotoGridViewController): the grid is no longer the browser's data source or delegate (an internal bridge is), so its display-index members (`numberOfPhotos`, `photo(at:)`, `photoDate(at:)`, …) are gone; ask your own data source (display order follows `sortOrder`), and reach the presented browser through `grid.browser`. |
| `LMKLogLevel\b\|LMKLogger\.logStore` | Review (optional): logging follows the 1.0 contract: `LMKLogLevel` adds `notice` and `fault` (an exhaustive `switch` needs both), warning writes at the unified log's error level, debug lines are no longer compiled out of Release (the default threshold is `.debug` in DEBUG and `.info` otherwise, clamped at `.error`), user data goes in `private:`, an attached error shows as a `[summary]` (domain and code) with its description private, and the store's `formatted()` lines carry an entry's private detail after ` \| `. |
