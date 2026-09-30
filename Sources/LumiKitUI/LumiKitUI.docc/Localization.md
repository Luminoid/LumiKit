# Localization

Every user-visible string in the kit is localized in English, Spanish, Simplified Chinese, and Traditional Chinese, and every one can be overridden.

## What ships

Each product carries its own string tables (`Resources/<locale>.lproj/Localizable.strings`), and each type that shows text has a nested `Strings` struct whose initializer defaults every field to the localized value:

```swift
public final class LMKSearchBar: UIView {
    public nonisolated struct Strings: Sendable, Equatable {
        public var placeholder: String
        public var cancel: String
        public init(placeholder: String = LMKLocalized("searchBar.placeholder"),
                    cancel: String = LMKLocalized("searchBar.cancel")) { ... }
    }
    public static var strings = Strings()        // process-wide default
    public var strings: Strings                  // per instance, on host-created types
}
```

The app's language decides which table is read. An app in one of the four languages needs nothing.

## Overriding

Set the process-wide default once at launch, or a single instance:

```swift
LMKSearchBar.strings = LMKSearchBar.Strings(placeholder: "Suchen", cancel: "Abbrechen")
LMKAlert.strings.ok = "OK"
cropViewController.strings = .init(done: "Fertig")
```

Accessibility labels, hints, and values are fields too (`accessibilityLabel`, `dismissAccessibilityLabel`, `pageFormat`), so VoiceOver follows the override.

## Formats

Strings with arguments use format specifiers (`%@`, `%lld`) and are resolved with the arguments at display time (`"%lld of %lld"` for a page counter), so word order can differ per language.

## Contributing a language

Add `<locale>.lproj/Localizable.strings` to every product's `Resources` folder with the same keys as `en.lproj`; a test per product checks that the key sets match and that no value equals its key.
