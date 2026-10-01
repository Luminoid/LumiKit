# Styling

Every component's appearance is a nested `Style` struct: all-optional fields, a shared surface vocabulary, per-state overrides, and escape hatches for what the Style does not cover.

## The Style pattern

```swift
var chip = LMKChipView.Style()
chip.variant = .filled
chip.tintColor = .systemPink
chip.surface.corners = .fixed(8)
chip.selected = LMKControlStateStyle(foregroundColor: .white)

let view = LMKChipView(text: "Sale", style: chip)
view.style = view.style.merging(.outlined)   // other's non-nil fields win
```

Rules that hold for every component:

- A field is on the Style when a designer decides it and it has no side effect beyond appearance: colors, text styles, radii, insets, sizes, shadow level, border width, variant and size enums, chrome visibility.
- A value stays a property of the instance when it is content or runtime state: text, icons, `isSelected`, `isLoading`, `isEnabled`, handlers, durations, placeholders.
- `nil` means "resolve from the theme at apply time", so a theme switch keeps flowing through fields you did not override.
- Presets (`.filled(.primary)`, `.outlined`, `.elevated`) set only their variant and never read tokens.
- Each Style conforms to ``LMKThemeExtension`` and has a slot on the theme, so `theme.<component>` is the app-wide default.

## The surface vocabulary

``LMKSurfaceStyle`` is embedded in every Style that draws a surface (cards, chips, badges, toasts, tips, sheets, panels, text fields, the navigation bar, list rows, calendar cells, and more):

| Field | Type | Options |
|---|---|---|
| `background` | ``LMKBackgroundStyle`` | `clear`, `solid(color)`, `gradient(colors:direction:locations:)`, `blur(style)`, `glass(variant, tint:)` |
| `corners` | ``LMKCornerStyle`` | `square`, `fixed(radius, corners:curve:)`, `capsule`, `circle`, `concentric(minimum:corners:curve:)` |
| `border` | ``LMKBorderStyle`` | `solid(color, width:)`, `dashed(pattern, color:width:)`, `hidden`, an `inset` for a stroke inside the bounds |
| `shadow` | ``LMKShadowSource`` | `hidden`, `level(.level1 ... .level5)`, `custom(LMKShadowStyle)` |
| `contentInsets` | `NSDirectionalEdgeInsets` | Padding around the content |

Every field is optional, and `nil` means "the theme decides". That is why the explicit "off" values are named `.square`, `.hidden`, and `.hidden` rather than `.none`: on an optional field Swift reads `.none` as `nil`, which would quietly keep the theme's border or shadow.

`UIView.lmk_apply(surface:defaults:)` applies one to any view: it installs the background (a color, a gradient layer, or an effect view), applies the corner style, and routes border and shadow through the re-stamping layer helpers. When a masking corner and a shadow are both present, the shadow goes on the view's layer and the content is clipped by an inner container.

## Per-state overrides

Controls carry ``LMKControlStateStyle`` fields named `highlighted`, `selected`, `disabled`, and `focused`. Each has optional `background`, `foregroundColor`, `border`, `alpha`, `scale`, and `shadow`; a `nil` state derives from the base look (a darkened background while pressed, the disabled alpha, and so on). Text inputs use the same idea keyed by ``LMKValidationState``: ``LMKTextInputStyle`` holds a state style for normal, focused, warning, error, and success, plus `disabled`. List rows take `highlighted` and `selected` from the cell's configuration state. A component that plays haptics has `haptics: Bool?` on its Style (`nil` means on).

## Text

Text never sets `.font` directly. `lmk_apply(_:color:)` on `UILabel`, `UITextField`, and `UITextView` takes an ``LMKTextStyle`` (`h1` to `h4`, `body`, `bodyMedium`, `bodyBold`, `subbodyMedium`, `caption`, `captionMedium`, `small`, `smallMedium`, the extra-small steps, italics, or `custom(LMKFontSpec)`), turns on Dynamic Type scaling, applies line height and kerning, and re-applies on theme and content-size changes. ``LMKTypographyTheme/maximumScale`` caps chrome at accessibility sizes. Heights in the kit are floors, never fixed values.

## Escape hatches

1. Every component exposes its structural subviews as `public private(set)` (`titleLabel`, `iconView`, `contentView`, `backgroundView`, ...).
2. Every component has `didApplyStyle: ((Self) -> Void)?`, invoked as the last step of `applyTheme(_:)` and therefore re-run on every theme, dark mode, contrast, and text-size change. A host tweak placed there survives a theme switch.
3. The open classes that a subclass extends (``LMKButton``, ``LMKBottomSheetViewController``, ``LMKCardPageViewController``, ``LMKCardPanelViewController``, ``LMKScrollStackViewController``, ``LMKSegmentedPageViewController``, ``LMKTabBarController``) call `open func applyContentTheme(_ theme: LMKTheme)` just before `didApplyStyle`. Style a subclass's own content there rather than after `super.applyTheme(_:)`, so `didApplyStyle` still runs last. The sheet subclasses layer their own sheet style through `resolveStyle(for:)`.
4. `LMKButton` rebuilds its `UIButton.Configuration` on every state change, so a configuration tweak made in a hook lasts until the next press; a tweak that must persist belongs in an `updateConfiguration()` override that calls `super`.
5. `Style.merging(_:)` builds hierarchies: `base.merging(.outlined).merging(brandOverrides)`.

## Writing a component

Conform to ``LMKThemeApplying``, resolve everything in `applyTheme(_:)` from the `theme` argument (never from `LMKTheme.current` or the global `LMKSpacing` / `LMKLayout` proxies, so a theme scoped to a window or subtree applies), and call `lmk_startApplyingTheme()` as the last line of `init`:

```swift
public final class TagView: UIView, LMKThemeApplying {
    public nonisolated struct Style: Sendable, Equatable, LMKThemeExtension {
        public var surface = LMKSurfaceStyle()
        public var textStyle: LMKTextStyle?
        public static let defaultValue = Style()
        public func merging(_ other: Style) -> Style { /* other's non-nil fields win */ }
    }

    public var style = Style() { didSet { applyTheme(traitCollection.lmkTheme) } }
    public private(set) lazy var label = UILabel()
    public var didApplyStyle: ((TagView) -> Void)?

    public init(style: Style = Style()) {
        self.style = style
        super.init(frame: .zero)
        addSubview(label)
        lmk_startApplyingTheme()
    }

    public func applyTheme(_ theme: LMKTheme) {
        let resolved = theme[Style.self].merging(style)
        lmk_apply(surface: resolved.surface, defaults: LMKSurfaceStyle(corners: .capsule))
        label.lmk_apply(resolved.textStyle ?? .captionMedium)
        didApplyStyle?(self)
    }
}
```
