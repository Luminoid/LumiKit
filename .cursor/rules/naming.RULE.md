---
description: "LumiKit naming conventions: LMK prefix, subject-noun namespaces, on<Event> callbacks, present(from:)/show(in:), lmk_ extensions, nested Style and Strings"
alwaysApply: true
---

# Naming Conventions

The full spec with rationale is in `CONTRIBUTING.md`; `Tests/LumiKitUITests/Naming` checks the mechanical rules over `Sources/`.

## Types

- **ALWAYS** prefix public top-level types with `LMK`; nested types never repeat it (`LMKButton.Variant`, not `LMKButtonVariant`)
- **`UIView` subclasses** end in the UIKit role noun (`View`, `Bar`, `Cell`, `Indicator`); **`UIControl` / `UIButton` subclasses** use the bare control noun (`LMKButton`, `LMKSwitch`, `LMKCheckbox`); wrappers keep the wrapped noun (`LMKTextField`)
- **View controllers** end in `ViewController` (`LMKBottomSheetViewController`), except subclasses of a UIKit class whose own name ends in `Controller` (`LMKNavigationController`, `LMKTabBarController`)
- **Namespaces** (caseless enums of statics) are subject nouns with no role suffix: `LMKAnimation`, `LMKHaptics`, `LMKDevice`, `LMKScene`, `LMKImage`, `LMKDate`, `LMKDateFormat`, `LMKFormat`, `LMKFile`, `LMKConcurrency`, `LMKAlert`, `LMKToast`, `LMKTip`, `LMKShare`, `LMKDatePicker`, `LMKEnumPicker`, `LMKSortMenu`
- **NEVER** use the suffixes `Helper`, `Util`, `Service`, `Manager`, `Type`, or `Config` on a public type; a role noun survives only when the role is the subject (`LMKLogger`, `LMKURLValidator`, `LMKMarkdownRenderer`, `LMKErrorHandler`)
- **Presenters** split namespace + class: the namespace owns `present` / `show` statics, `Strings`, and value types; the class is `LMK<Thing>View` or `LMK<Thing>ViewController` (`LMKToast` / `LMKToastView`, `LMKActionSheet` / `LMKActionSheetViewController`)
- **Protocols**: `LMK<Thing>DataSource` / `LMK<Thing>Delegate` only for multi-method content providers; `-able` / `-ing` adjectives for capabilities (`LMKEnumSelectable`, `LMKThemeApplying`, `LMKLogging`); `LMK<Category>Theme` for token categories
- **Enums**: the visual variant is nested `Variant`; layout / placement modes are nested and named for what they select (`Layout`, `Placement`, `Mode`, `Corners`); the shared status is `LMKStatus`; every public enum without reference-type or closure payloads is `Sendable` + `Hashable` (`CaseIterable` when the UI enumerates it); enums carrying views, images, errors, or closures are neither
- **Explicit-off values**: `nil` in an optional style field means "the theme decides", so **NEVER** name a case `.none` there (Swift reads it as `nil`); the overrides are `LMKCornerStyle.Radius.square`, `LMKBorderStyle.hidden`, `LMKShadowSource.hidden`
- **`Style`** is reserved for the per-component token struct; **`Strings`** for the per-component string struct
- **`open`** only where subclassing is the extension point (base controllers, `LMKNavigationController`, `LMKTabBarController`, `LMKCalendarDayCell`, `LMKButton`); everything else `final`. Every open base calls `open func applyContentTheme(_ theme: LMKTheme)` just before `didApplyStyle`: subclasses style their content there, and `didApplyStyle` always runs last

## Members

- **Callbacks**: present-tense `on<Event>` closures whose payload is the new value, no sender: `onTap`, `onDismiss`, `onDayTap`, `onMonthChange`, `onTextChange`, `onSelectionChange` (`Set<Int>`), `onBack`; a value change is `onValueChange`. **NEVER** `*Handler` names, `didTapHandler`, a bare `onChange`, or past tense (`onTapped`, `onChanged`): the naming test rejects them. A presenter that can be cancelled offers `onCancel`; `dismiss()` is idempotent and fires `onDismiss` once
- **Controls** honor `isEnabled` the UIKit way in `point(inside:with:)`: hidden answers `false`, disabled answers `bounds.contains(point)` (touches absorbed, never passed through), enabled answers the 44pt area
- **Destructive defaults are off**: nothing deletes or overwrites user data unless asked (`deletesAfterShare` defaults to `false`); a parameter in pixels is `…PixelSize`, an exact value is never `max…`
- **`LMKCalendarDay` / `LMKCalendarMonth` are Gregorian civil dates** whatever calendar is supplied: math through `Calendar.lmk_civilCalendar`, deltas anchored at noon, display in the supplied calendar only when its months are Gregorian
- **Presentation verbs**: `present(from:)` for anything that ends in `host.present(...)`; `show(in:)` for views installed into a hierarchy (toast, tip, banner, floating button); `dismiss()` everywhere; `completion:` for completion closures
- **State**: UIKit's names when UIKit has the concept (`isOn`, `value`, `isEnabled`, `isSelected`, `selectedSegmentIndex`, `currentPage`); otherwise `is<Adjective>`, `selectedIndex` / `selectedIndices`
- **`init` vs `configure`**: `init` takes identity that never changes; `configure(...)` is the single re-bind on reusable views; animated changes are `set<Prop>(_:animated:)`
- Members of `LMK` types **never** carry `lmk_`

## Strings

Exactly one idiom:

```swift
public final class LMKSearchBar: UIView {
    public nonisolated struct Strings: Sendable, Equatable {
        public var cancel: String
        public var clearAccessibilityLabel: String
        public init(cancel: String = LMKLocalized("searchBar.cancel"),
                    clearAccessibilityLabel: String = LMKLocalized("searchBar.clear.accessibilityLabel")) { ... }
    }
    public nonisolated(unsafe) static var strings = Strings()   // process-wide default, written once at launch
    public var strings: Strings                                 // per instance on host-created types
}
```

- **NEVER** top-level `LMK*Strings` types or module-level `lmk*Strings` globals
- **NEVER** a literal user-facing string in `Sources/` (SwiftLint `no_literal_user_strings`); every key exists in `en`, `es`, `zh-Hans`, `zh-Hant`

## Extensions and files

- **ALWAYS** prefix public members of extensions on non-LMK types with `lmk_`, in every product including Core (`[lmk_safe:]`, `lmk_nonEmpty`, `lmk_trimmedOrNil`, `lmk_appending(_:)`)
- **File naming**: one primary public type per file, named after it; closely related value types, protocols, and handles may share the file (`LMKToast.swift` holds `LMKToast` and its nested types, `LMKSurfaceStyle.swift` the surface vocabulary); extensions `{Type}+LMK{Feature}.swift` (`UIView+LMKCorners.swift`, named for the API they add, not for a 0.x name); large types split into `LMKType+Aspect.swift` (`LMKSegmentedControl+Layout.swift`). Controls live in `Controls/` (`LMKSearchBar`, `LMKActionTile` included); a test file mirrors its subject's folder
