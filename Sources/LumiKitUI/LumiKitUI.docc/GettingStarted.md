# Getting Started

Link the products you need, apply a theme at launch, and build screens from tokens, components, and presenters.

## Add the package

```swift
dependencies: [
    .package(url: "https://github.com/Luminoid/LumiKit.git", from: "1.0.0"),
],
targets: [
    .target(name: "MyApp", dependencies: [
        .product(name: "LumiKitUI", package: "LumiKit"),
        .product(name: "LumiKitPhoto", package: "LumiKit"),   // photo browser, grid, crop, share preview
        .product(name: "LumiKitLottie", package: "LumiKit"),  // Lottie pull-to-refresh
    ]),
]
```

`LumiKitDebug` (network capture and the request inspector) belongs in debug builds only. `LumiKitCore` is linked with `LumiKitUI` but not re-exported: add `import LumiKitCore` in files that name its types (`LMKLogger`, `LMKDateFormat`, `LMKCalendarDay`), and link it on its own for a target without UIKit.

## Apply a theme

A theme is a value. Override the roles that differ from the defaults and apply it once at launch; every window re-renders if you apply another one later.

```swift
import LumiKitUI

extension LMKTheme {
    static let myApp = LMKTheme(
        colors: LMKColorTheme(primary: .systemIndigo, secondary: .systemTeal),
        cornerRadius: LMKCornerRadiusTheme(medium: 14)
    )
}

// In the app delegate or scene delegate, before the first window:
LMKTheme.apply(.myApp)
```

## Use tokens

Tokens read the current theme and are `nonisolated`, so they work in `static let` defaults and SwiftUI views. Colors are dynamic: a view that holds `LMKColor.primary` re-resolves it on theme, dark mode, and Increase Contrast changes without any code.

```swift
view.backgroundColor = LMKColor.backgroundPrimary
stack.spacing = LMKSpacing.large
card.lmk_applyCornerStyle(.fixed(LMKCornerRadius.large))
titleLabel.lmk_apply(.h2)                       // font, Dynamic Type, line height, kern
let caption = UILabel.lmk_make(.caption, text: "Updated today")
```

## Build with components

Components take a `Style`; content and state are properties; callbacks are `on<Event>` closures.

```swift
let save = LMKButton(title: "Save", style: .filled(.primary)) { save() }
let chip = LMKChipView(text: "Outdoor", style: .outlined.tint(.systemGreen))
chip.onTap = { [weak chip] in chip?.isSelected.toggle() }

let row = LMKListRowConfiguration(
    title: "Watering",
    subtitle: "Every 3 days",
    leading: .symbol("leaf", tint: LMKColor.success),
    trailing: .disclosure
)
cell.lmk_applyListRow(row)
```

## Present

Anything that ends in `host.present(...)` takes `from:`; views installed into a hierarchy use `show(in:)`.

```swift
LMKToast.show(.success, "Saved", in: self)
LMKAlert.presentDeleteConfirmation(from: self, itemName: "Photo", onConfirm: { delete() })
LMKEnumPicker.present(from: self, title: "Sort", options: Sort.allCases, selection: sort) { sort = $0 }
LMKShare.image(image, from: self, sourceView: button)
```

## Next

- <doc:Theming> for the token categories, app-wide component defaults, and previewing a theme in one window.
- <doc:Styling> for the `Style` vocabulary and the escape hatches.
- <doc:ComponentCatalog> and <doc:ControlCatalog> for the catalog.
