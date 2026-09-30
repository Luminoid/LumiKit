# Migrating to 1.0

Move a 0.x consumer to LumiKit 1.0 with the migration script and a short list of hand edits.

## Overview

LumiKit 1.0 renames most public types, splits the package into five products, replaces the theme manager with the ``LMKTheme`` value, and moves component appearance into `Style` structs. The repository ships `Scripts/migrate-1.0.sh`, which rewrites the mechanical part and reports the rest by file and line, and `docs/MIGRATION-1.0.md`, which carries the full rename tables and recipes. This page is the short version.

## Steps

1. **Products.** `LumiKitNetwork` is `LumiKitDebug`; the photo browser, grid, crop editor, coordinator, and share preview moved to `LumiKitPhoto`. Link what you use and add the imports (the script inserts them where it can).
2. **Run the script.** `Scripts/migrate-1.0.sh <consumer-dir> --dry-run` shows the counts and the report; run it again without the flag to rewrite. A marker file blocks a second run because the `LMKTheme` rename is not idempotent.
3. **Convert the theme.** A `struct MyTheme: LMKTheme` conformance becomes `extension LMKTheme { static let my = LMKTheme(colors: LMKColorTheme(primary: ...)) }`, applied with ``LMKTheme/apply(_:)``. Per-category `apply(spacing:)` calls become ``LMKTheme/update(_:)``.
4. **Apply the recipes the report lists.** The common ones: `addAsChild(sheet, in:)` becomes `sheet.present(from:)`; `LMKCardPanelController.show(panel, in:)` becomes `panel.present(from:)`; the search bar, crop, and share-preview delegates become closures; `didTapHandler` becomes `onTap`; a multi-line call still passing `on:` renames it to `from:` (or `in:` for toasts and tips); `LMKEnumSelectable.iconName` becomes `String?`; EXIF reads move to `LMKPhotoMetadata.read(from:)` on the picked bytes; `LMKConcurrency.encode` and `decode` throw.
5. **Delete what the kit now covers.** Dead `lmk_hitTestInsets` assignments (LumiKit controls enforce 44pt themselves), app copies of the Lottie ring, LumiKit string overrides in a language the package ships, and app-local components with a LumiKit counterpart (month calendar, sort menu, tab bar controller, detail cards, list cells, action tiles, ratings, copyable labels, photo buttons, checkboxes).
6. **Build and check.** A clean build with zero warnings, the test suite, a run on an iPhone simulator and on Mac Catalyst for Mac apps, and a pass through dark mode, Increase Contrast, and an accessibility text size.

## Renamed types at a glance

| 0.x | 1.0 |
|---|---|
| `LMKThemeManager`, `LMKTheme` (protocol), `LMKDefaultTheme` | ``LMKTheme`` (struct), ``LMKColorTheme`` |
| `LMKAnimationHelper`, `LMKHapticFeedbackHelper`, `LMKDeviceHelper`, `LMKSceneUtil`, `LMKImageUtil` | ``LMKAnimation``, ``LMKHaptics``, ``LMKDevice``, ``LMKScene``, ``LMKImage`` |
| `LMKAlertPresenter`, `LMKCountdownConfirmation` | ``LMKAlert`` |
| `LMKShareService`, `LMKDatePickerHelper`, `LMKEnumSelectionBottomSheet` | ``LMKShare``, ``LMKDatePicker``, ``LMKEnumPicker`` |
| `LMKBottomSheetController`, `LMKCardPageController`, `LMKCardPanelController`, `LMKSegmentedPageController` | ``LMKBottomSheetViewController``, ``LMKCardPageViewController``, ``LMKCardPanelViewController``, ``LMKSegmentedPageViewController`` |
| `LMKToastType`, `LMKBannerType` | ``LMKStatus`` |
| `LMKButtonFactory`, `LMKLabelFactory`, `LMKCardFactory` | ``LMKButton`` initializers, `UILabel.lmk_make`, ``LMKCardView`` styles |
| `LMKToast.showSuccess(message:on:)` and the other nine entry points | ``LMKToast/show(_:_:duration:in:completion:)`` |

The complete tables, including dotted paths, members, and every hand-edit recipe, are generated from the rules file into `docs/MIGRATION-1.0.md`.
