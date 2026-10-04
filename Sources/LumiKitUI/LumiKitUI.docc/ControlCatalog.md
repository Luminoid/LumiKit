# Controls

Every control honors `isEnabled` and answers `point(inside:with:)` the way UIKit's controls do: a 44pt hit area while enabled, its own bounds while disabled (the touch is absorbed, never passed to the view behind), nothing while hidden. Every control scales with Dynamic Type and exposes its state through VoiceOver; toggles carry the toggle-button trait.

| Control | Purpose |
|---|---|
| ``LMKButton`` | Roles (`primary`, `secondary`, `tertiary`, `destructive`, `success`, `warning`, `info`, `neutral`) by variants (`filled`, `tinted`, `outlined`, `ghost`, `glass`, icon-only) by sizes; `title`, `image`, `setSymbol(_:)`, `isLoading`, `isToggle` with `selectedTitle` / `selectedImage`, `menu` with `showsMenuIndicator`, `shrinkingTitleToFit(minimumScaleFactor:)`, `onTap`, `onValueChange` |
| ``LMKCheckbox`` | A checkbox with `isChecked`, `setChecked(_:animated:)`, and `onValueChange` |
| ``LMKRatingControl`` | Star ratings with `maximum`, a clamped `value`, `isInteractive`, retap-to-clear, and the `adjustable` trait |
| ``LMKSegmentedControl`` | A sliding-pill segmented control with `Layout` (`equalWidth`, `fitContent`, `scrollable`), segment editing, per-segment enabling, and `onValueChange` |
| ``LMKSlider`` | A slider with an optional caption and live readout, `step` snapping (with ticks on iOS 26 when the steps divide the range evenly into at most 50 stops), `neutralValue`, a localized VoiceOver value, and `onValueChange` for changed values only |
| ``LMKSwitch`` | A custom toggle with `isOn`, `setOn(_:animated:)`, and `onValueChange` |
| ``LMKTextField`` | A text field with a leading icon, helper text, a counter, an ``LMKValidationState``, the kit's own clear button (`clearButton`, shown while editing with text when `showsClearButton` is on), `Strings`, and `onTextChange`, `onBeginEditing`, and `onEndEditing` |
| ``LMKTextView`` | A multi-line input with a placeholder, a counter, and growth between `minimumHeight` and `maximumHeight`, scrolling past the cap |
| ``LMKSearchBar`` | A search field with `onTextChange`, `onDebouncedTextChange` (a pending call is dropped by Cancel, Return, and setting `text`), `onSearch`, `onCancel`, and a `cancelButtonMode` |
| ``LMKCopyableLabel`` | A label with a Copy edit menu and `onCopy` |
| ``LMKPhotoButton`` | A circular or rounded photo well with a placeholder, `onTap`, and `onDropImage` for an image dragged onto it (its original bytes) |
| ``LMKActionTile`` | A tile with an icon, title, and count, tinted by an accent color, for dashboards; `Style.glyphMinimumContrast` softens the glyph to the softest tone that keeps a WCAG ratio against the tile, `titleMinimumScaleFactor` shrinks a long title, `minimumHeight` sets a floor, and the large content viewer shows the title at accessibility sizes |

## Buttons

```swift
let primary = LMKButton(title: "Continue", style: .filled(.primary)) { next() }
let quiet = LMKButton(title: "Not now", style: .ghost(.neutral))
let icon = LMKButton(systemImage: "heart", style: .iconOnly(.destructive)) { like() }
let custom = LMKButton(title: "Brand", style: .tinted().tint(.systemPurple).size(.large))

primary.isLoading = true            // spinner, touches absorbed, the current title kept
icon.isToggle = true                // taps flip isSelected and call onValueChange
icon.selectedImage = UIImage(systemName: "heart.fill")
```

State looks derive from the base style: pressed darkens the fill (or scales by `highlighted.scale`, else the theme's press scale), disabled applies the alpha token, selected uses the darker tint. Override any of them per instance or app-wide through ``LMKControlStateStyle`` fields on `LMKButton.Style`. `setSymbol(_:)` without a point size or weight leaves both to the style, so they follow theme changes. A subclass styles its own additions in `applyContentTheme(_:)`, which runs before `didApplyStyle`; a change to the `UIButton.Configuration` that must survive state changes belongs in an `updateConfiguration()` override.

## Text input

``LMKTextField`` and ``LMKTextView`` share ``LMKTextInputStyle`` and forward every `UITextFieldDelegate` / `UITextViewDelegate` method (and, for the text view, every `UIScrollViewDelegate` method) to the delegate the host assigns; a host's refusal wins. `maxCharacterCount` counts characters as a reader sees them, never cuts text while an input method is composing, and trims an over-limit paste to fit instead of rejecting it. The validation message (or the helper text) is the VoiceOver hint, and the counter reads as "5 of 40 characters".

## Custom controls

The hit-area helper for controls you write yourself lives on `UIControl`: set `lmk_hitTestInsets` and call `lmk_point(inside:with:)` from your `point(inside:with:)` override; it answers `false` while hidden and the plain bounds while disabled, like the kit's controls. ``LMKAnimation/animateButtonPress(_:completion:)`` provides the press animation, and ``LMKHaptics`` the feedback.
