# Extensions

Every member added to a UIKit or Foundation type carries the `lmk_` prefix.

## Views and layers

| Extension | Members |
|---|---|
| `UIView` corners | `lmk_applyCornerStyle(_:)`, `lmk_applyCornerRadius(_:masking:asConcentricContainer:)`, `lmk_applyConcentricCorners(minimumRadius:)`, `lmk_makeCircular()` |
| `UIView` layer colors | `lmk_applyShadow(_ level:)`, `lmk_applyShadow(_ style:)`, `lmk_removeShadow()`, `lmk_applyBorder(color:width:)`, `lmk_removeBorder()`; sources re-stamp on theme, dark mode, and contrast changes |
| `UIView` surfaces | `lmk_apply(surface:defaults:)` for an ``LMKSurfaceStyle`` |
| `UIView` layout | `lmk_pinReadableWidth(in:maxWidth:horizontalInset:)`, `lmk_readableWidthGuide`, `lmk_displayScale`, `lmk_forceLayoutDirection(_:)`, `lmk_forcedLayoutDirection` |
| `UIStackView` | `init(lmk_axis:...)`, `lmk_addArrangedSubviews(_:)`, `lmk_removeAllArrangedSubviews()` |
| `UIControl` | `lmk_hitTestInsets` with `lmk_point(inside:with:)` for custom controls (hidden answers `false`, disabled answers its bounds, enabled the inset area) |

## Text

| Extension | Members |
|---|---|
| `UILabel` | `lmk_make(_:text:color:numberOfLines:)`, `lmk_apply(_:color:lineMetrics:)` |
| `UITextField`, `UITextView` | `lmk_apply(_:color:)`, `lmk_dismissKeyboardOnReturn()`, the form style helpers |
| `UIColor` | `init(lmk_hex:)`, `lmk_dynamic(lightHex:darkHex:alpha:)`, `lmk_hexString`, `lmk_isLight`, `lmk_adjustedBrightness(by:)` (a multiplier: `0.85` darkens by 15 percent), `lmk_contrastingTextColor`, `lmk_glyphTint(onLightAccentDarkenBy:)` |
| `UIImage` | `lmk_resized(maxDimension:)`, `lmk_resized(to:)`, `lmk_solidColor(_:size:)`, `lmk_rounded(cornerRadius:)` |

## Cells and lists

| Extension | Members |
|---|---|
| `UITableViewCell`, `UICollectionViewCell` | `lmk_applyListRow(_:backgroundColor:pointer:)`, `lmk_configureCustomHighlight()`, `lmk_applyCustomHighlight(highlighted:animated:)` through ``LMKHighlightable`` |
| `UIListContentConfiguration` | `lmk_applyTextStyle`, `lmk_applyLeadingSymbol`, `lmk_applyThumbnail` |
| `UIView` | `lmk_installRowPointerInteraction(_:)` |
| Diffable data sources | `lmk_apply(_:animatingDifferences:in:)` diffs only while the view is in a window |

## View controllers and scenes

| Extension | Members |
|---|---|
| `UIViewController` | `lmk_formKeyCommands(save:cancel:)` with an overridable `lmk_cancelFromKeyCommand()`, `lmk_dismissKeyboardOnTap()`, `lmk_topViewController(controller:)` (static), `lmk_presentAlertOnTop(_:animated:)`, `lmk_configurePopoverForActionSheet(_:)`, `lmk_centeredPopoverSourceRect`, `lmk_windowOrientation` (camera and media rotation only) |
| `UIScrollView` | `lmk_enableKeyboardAdjustment()` and `lmk_disableKeyboardAdjustment()` (restores the insets it grew) |
| `UINavigationItem` | `lmk_setItems(leading:trailing:tintColor:)` (an omitted side is left alone, `[]` clears it), `lmk_setSubtitle(_:)` |
| `UISplitViewController` | `lmk_setInspector(_:preferredWidth:)`, `lmk_supportsInspector`, `lmk_inspector`, `lmk_isShowingInspector`, `lmk_setInspectorShown(_:)`, `lmk_toggleInspector()` |

## Foundation (LumiKitCore)

`Collection[lmk_safe:]`, `lmk_uniqued()`, `lmk_chunked(size:)`, `String.lmk_trimmedOrNil`, `String?.lmk_nonEmpty`, `NSAttributedString.lmk_appending(_:)`, `Date.lmk_startOfDay`, `lmk_isToday`, `lmk_isSameDay(as:)`, `Date.lmk_string(_:time:)`.
