# Localization

Every user-visible string in the kit is localized in English, Spanish, Simplified Chinese, and Traditional Chinese, and every one can be overridden.

## What ships

Each product carries its own string tables (`Resources/<locale>.lproj/Localizable.strings`), and each type that shows text has a nested `Strings` struct whose initializer defaults every field to the localized value:

```swift
public final class LMKSearchBar: UIView {
    public nonisolated struct Strings: Sendable, Equatable {
        public var cancel: String
        public var clearAccessibilityLabel: String
        public init(cancel: String = LMKLocalized("searchBar.cancel"),
                    clearAccessibilityLabel: String = LMKLocalized("searchBar.clear.accessibilityLabel")) { ... }
    }
    public nonisolated(unsafe) static var strings = Strings()   // process-wide default, set once at launch
    public var strings: Strings                                 // per instance, on host-created types
}
```

The app's language decides which table is read. An app in one of the four languages needs nothing.

## Overriding

Set the process-wide default once at launch, or a single instance:

```swift
LMKSearchBar.strings = LMKSearchBar.Strings(cancel: "Abbrechen", clearAccessibilityLabel: "Löschen")
LMKAlert.strings.ok = "OK"
cropViewController.strings = .init(done: "Fertig")
```

Accessibility labels, hints, and values are fields too (`accessibilityLabel`, `dismissAccessibilityLabel`, `pageFormat`), so VoiceOver follows the override.

## Formats

Strings with arguments use format specifiers (`%@`, `%lld`) and are resolved with the arguments at display time (`"%lld of %lld"` for a page counter), so word order can differ per language; positional specifiers let a translation reorder them (`alert.countdownConfirmation.confirmTitleFormat` is `"%1$@ (%2$lld)"` in English and uses full-width parentheses in Chinese). Numbers shown to the user (counts, slider values, durations) go through `LMKFormat` so they follow the locale's digits and grouping. A test per product checks that every format key keeps the same specifiers in every locale and that the keys looked up in the sources match the English table.

## Contributing a language

Add `<locale>.lproj/Localizable.strings` to every product's `Resources` folder with the same keys as `en.lproj`; a test per product checks that the key sets match and that no value equals its key.
