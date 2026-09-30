# Controls

Every control honors `isEnabled`, answers a 44pt hit area from `point(inside:with:)`, scales with Dynamic Type, and exposes its state through VoiceOver.

| Control | Purpose |
|---|---|
| ``LMKButton`` | Roles (`primary`, `secondary`, `tertiary`, `destructive`, `success`, `warning`, `info`, `neutral`) by variants (`filled`, `tinted`, `outlined`, `ghost`, `glass`, icon-only) by sizes; `title`, `image`, `setSymbol(_:)`, `isLoading`, `isToggle` with `selectedTitle` / `selectedImage`, `menu` with `showsMenuIndicator`, `onTap`, `onValueChange` |
| ``LMKCheckbox`` | A checkbox with `isChecked`, `setChecked(_:animated:)`, and `onToggle` |
| ``LMKRatingControl`` | Star ratings with `maximum`, a clamped `value`, `isInteractive`, retap-to-clear, and the `adjustable` trait |
| ``LMKSegmentedControl`` | A sliding-pill segmented control with `Layout` (`equalWidth`, `fitContent`, `scrollable`), segment editing, per-segment enabling, and `onValueChange` |
| ``LMKSlider`` | A slider with an optional caption and live readout, `step` snapping with ticks on iOS 26, `neutralValue`, and `onValueChange` |
| ``LMKSwitch`` | A custom toggle with `isOn`, `setOn(_:animated:)`, and `onValueChange` |
| ``LMKTextField`` | A text field with a leading icon, helper text, a counter, an ``LMKValidationState``, and `onTextChange` / `onEditingChange` |
| ``LMKTextView`` | A multi-line input with a placeholder, a character limit, and growth between `minimumHeight` and `maximumHeight` |
| ``LMKSearchBar`` | A search field with `onTextChange`, `onDebouncedTextChange`, `onSearch`, `onCancel`, and a `cancelButtonMode` |
| ``LMKCopyableLabel`` | A label with a Copy edit menu and `onCopied` |
| ``LMKPhotoButton`` | A circular or rounded photo well with a placeholder and `onTap` |
| ``LMKActionTile`` | A tile with an icon, title, and count, tinted by an accent color, for dashboards |

## Buttons

```swift
let primary = LMKButton(title: "Continue", style: .filled(.primary)) { next() }
let quiet = LMKButton(title: "Not now", style: .ghost(.neutral))
let icon = LMKButton(systemImage: "heart", style: .iconOnly(.destructive)) { like() }
let custom = LMKButton(title: "Brand", style: .tinted().tint(.systemPurple).size(.large))

primary.isLoading = true            // spinner, interaction off, title kept
icon.isToggle = true                // taps flip isSelected and call onValueChange
icon.selectedImage = UIImage(systemName: "heart.fill")
```

State looks derive from the base style: pressed darkens the fill, disabled applies the alpha token, selected uses the darker tint. Override any of them per instance or app-wide through ``LMKControlStateStyle`` fields on `LMKButton.Style`.

## Custom controls

The hit-area helper for controls you write yourself lives on `UIControl`: set `lmk_hitTestInsets` and call `lmk_point(inside:with:)` from your `point(inside:with:)` override. ``LMKAnimation/animateButtonPress(_:completion:)`` provides the press animation, and ``LMKHaptics`` the feedback.
