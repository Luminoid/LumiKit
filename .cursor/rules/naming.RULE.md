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
- **Enums**: the visual variant is nested `Variant`; layout / placement modes are nested and named for what they select (`Layout`, `Placement`, `Mode`, `Corners`); the shared status is `LMKStatus`; every public enum is `Sendable` + `Hashable`, `CaseIterable` when the UI enumerates it
- **`Style`** is reserved for the per-component token struct; **`Strings`** for the per-component string struct
- **`open`** only where subclassing is the extension point (base controllers, `LMKNavigationController`, `LMKTabBarController`, `LMKCalendarDayCell`, `LMKButton`); everything else `final`

## Members

- **Callbacks**: `on<Event>` closures whose payload is the new value, no sender: `onTap`, `onDismiss`, `onValueChange`, `onTextChange`, `onSelectionChange` (`Set<Int>`), `onBack`. **NEVER** `*Handler` names or `didTapHandler`
- **Presentation verbs**: `present(from:)` for anything that ends in `host.present(...)`; `show(in:)` for views installed into a hierarchy (toast, tip, banner, floating button); `dismiss()` everywhere; `completion:` for completion closures
- **State**: UIKit's names when UIKit has the concept (`isOn`, `value`, `isEnabled`, `isSelected`, `selectedSegmentIndex`, `currentPage`); otherwise `is<Adjective>`, `selectedIndex` / `selectedIndices`
- **`init` vs `configure`**: `init` takes identity that never changes; `configure(...)` is the single re-bind on reusable views; animated changes are `set<Prop>(_:animated:)`
- Members of `LMK` types **never** carry `lmk_`

## Strings

Exactly one idiom:

```swift
public final class LMKSearchBar: UIView {
    public nonisolated struct Strings: Sendable, Equatable {
        public var placeholder: String
        public init(placeholder: String = LMKLocalized("searchBar.placeholder")) { ... }
    }
    public static var strings = Strings()   // process-wide default
    public var strings: Strings             // per instance on host-created types
}
```

- **NEVER** top-level `LMK*Strings` types or module-level `lmk*Strings` globals
- **NEVER** a literal user-facing string in `Sources/` (SwiftLint `no_literal_user_strings`); every key exists in `en`, `es`, `zh-Hans`, `zh-Hant`

## Extensions and files

- **ALWAYS** prefix public members of extensions on non-LMK types with `lmk_`, in every product including Core (`[lmk_safe:]`, `lmk_nonEmpty`, `lmk_trimmedOrNil`, `lmk_appending(_:)`)
- **File naming**: one public type per file named after it; extensions `{Type}+LMK{Feature}.swift` (`UIView+LMKCorners.swift`); large types split into `LMKType+Aspect.swift` (`LMKSegmentedControl+Layout.swift`)
