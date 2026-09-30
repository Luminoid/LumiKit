# Contributing to LumiKit

Thanks for helping. This page covers the toolchain, the checks that run before a commit, the pull request flow, the naming rules the codebase follows, and the checklist for a new component.

## Toolchain

- Xcode 26 (Swift 6.2) or Xcode 27 (Swift 6.4). The deployment floor is iOS 18 / Mac Catalyst 18 / macOS 15. Swift 6.4 isolates the members of an extension to the module's default actor, so an extension on a nonisolated type whose members should run anywhere is declared `nonisolated extension`.
- Homebrew tools: `brew bundle` installs SwiftLint, SwiftFormat, and XcodeGen (versions in `Brewfile`).
- `make setup-hooks` points `core.hooksPath` at `Scripts/git-hooks`, so every commit runs SwiftLint (strict) and SwiftFormat (lint) on the staged Swift files and refuses a personal `DEVELOPMENT_TEAM` in the Example project.

## Build and test

| Target | Command |
|---|---|
| Lint and format check | `make check` (`make lint-fix` and `make format` apply fixes) |
| Build (iOS Simulator) | `make build` |
| Build (Mac Catalyst) | `make build-catalyst` |
| Build Core and Debug natively on macOS | `make build-host` |
| Tests (iOS Simulator) | `make test` (`make test-filter FILTER=LumiKitUITests/LMKButtonTests` for one suite) |
| Example app | `make example` (regenerates the project with XcodeGen, then builds) |
| DocC archives | `make docs` |

`DEST` overrides the simulator (`make test DEST='platform=iOS Simulator,name=iPhone 17'`). UIKit targets cannot run under `swift test`; only the Foundation-only targets build natively.

CI (`.github/workflows/ci.yml`) runs the same steps with `LUMIKIT_WARNINGS_AS_ERRORS=1`, which turns every warning into an error in `Package.swift`. Keep the tree warning-free.

## Pull requests

1. Branch from `main`, keep the change focused, and add or update tests next to the code (`Tests/<Target>Tests/<same folder>`).
2. Run `make check` and `make test` before opening the PR. Add `make build-catalyst` when the change touches layout, gestures, or anything with a Mac idiom branch.
3. Add a CHANGELOG entry under `[Unreleased]` in the section that fits (Added, Changed, Fixed, Removed). Write it for a consumer: what changed, what to call instead.
4. Public API changes need a DocC comment on every new symbol and, for a rename or removal, a rule in `Scripts/migrate-1.0.rules` (renames as `path` / `type` / `member` rules, hand edits as `report` rules) so the migration script keeps up.
5. Squash-merge with a message that names the theme of the change.

## Naming

Every public symbol follows these rules; a test in `LumiKitUITests/Naming` checks the ones that can be checked mechanically.

| Category | Rule |
|---|---|
| Prefix | Every public top-level type carries `LMK`; nested types never repeat it (`LMKButton.Variant`). |
| Views and controls | `UIView` subclasses end in the UIKit role noun (`View`, `Bar`, `Cell`, `Indicator`); `UIControl` and `UIButton` subclasses use the bare control noun (`LMKButton`, `LMKSwitch`, `LMKCheckbox`); wrappers keep the wrapped control's noun (`LMKTextField`). |
| View controllers | Every `UIViewController` subclass ends in `ViewController`, except subclasses of a UIKit class whose own name ends in `Controller` (`LMKNavigationController`, `LMKTabBarController`). |
| Namespaces | Caseless enums of statics are named for the subject noun with no role suffix: `LMKAnimation`, `LMKHaptics`, `LMKDevice`, `LMKScene`, `LMKImage`, `LMKDate`, `LMKDateFormat`, `LMKFormat`, `LMKFile`, `LMKConcurrency`, `LMKAlert`, `LMKToast`, `LMKTip`, `LMKShare`, `LMKDatePicker`, `LMKEnumPicker`, `LMKPhotoMetadata`, `LMKMenu`, `LMKSortMenu`, `LMKFormScaffold`, `LMKPointerStyle`. The suffixes `Helper`, `Util`, `Service`, and `Manager` are banned. A role noun survives only when the role is the subject (`LMKLogger`, `LMKURLValidator`, `LMKMarkdownRenderer`, `LMKErrorHandler`). |
| Presenters | A namespace owns the `present` / `show` statics, `Strings`, and nested value types; the class is `LMK<Thing>View` or `LMK<Thing>ViewController` (`LMKToast` / `LMKToastView`, `LMKActionSheet` / `LMKActionSheetViewController`). |
| Protocols | `LMK<Thing>DataSource` / `LMK<Thing>Delegate` only for multi-method content providers (photo browser, grid); `-able` or `-ing` adjectives for capabilities (`LMKEnumSelectable`, `LMKHighlightable`, `LMKThemeApplying`, `LMKLogging`); `LMK<Category>Theme` for token categories. |
| Enums | The visual variant of a component is a nested `Variant`; layout and placement modes are nested and named for what they select (`LMKEmptyStateView.Layout`, `LMKTipView.Placement`, `LMKProgressViewController.Mode`). The shared semantic status is `LMKStatus`. `Style` is reserved for the per-component token structs; `Type` is banned as a suffix. Every public enum is `Sendable` and `Hashable`, and `CaseIterable` when the UI enumerates it. |
| Strings | Exactly one idiom: a nested `public nonisolated struct Strings: Sendable, Equatable` whose initializer defaults every field to `LMKLocalized("key")`, a `static var strings` process-wide default, and an instance `strings` on host-instantiated types. No top-level `LMK*Strings`, no `lmk*Strings` globals, no literal user-facing strings in `Sources/` (SwiftLint `no_literal_user_strings`). |
| Styles | Every component has a nested `public nonisolated struct Style: Sendable, Equatable, LMKThemeExtension` with all-optional fields, an embedded `LMKSurfaceStyle` when it draws a surface, per-state `LMKControlStateStyle` fields when it is a control, `merging(_:)`, and a slot on `LMKTheme` (`theme.<component>`). Components never read `LMKTheme.current` (SwiftLint `no_theme_store_in_components`); they resolve against the `theme` passed to `applyTheme(_:)`. |
| Callbacks | `on<Event>` closures whose payload is the new value and no sender: `onTap`, `onDismiss`, `onValueChange`, `onTextChange`, `onSelectionChange`, `onBack`. |
| Presentation verbs | `present(from:)` for anything that ends in `host.present(...)`; `show(in:)` for views installed into a hierarchy; `dismiss()` everywhere; `completion:` for completion closures. |
| State | UIKit's names when UIKit has the concept (`isOn`, `value`, `isEnabled`, `isSelected`, `selectedSegmentIndex`, `currentPage`); otherwise `is<Adjective>` and `selectedIndex` / `selectedIndices`. |
| configure vs init | `init` takes identity that does not change; `configure(...)` is the single re-bind on reusable views; animated state changes are `set<Prop>(_:animated:)`. Members of `LMK` types never carry `lmk_`. |
| Extensions | `lmk_` on every public member of an extension on a non-LMK type, in every product, including Core (`[lmk_safe:]`, `lmk_nonEmpty`, `lmk_appending(_:)`). |
| `open` vs `final` | `open` only where subclassing is the intended extension point: the base controllers, `LMKNavigationController`, `LMKTabBarController`, `LMKCalendarDayCell`, `LMKButton`. Everything else is `final`. |
| Public vs internal | Public means used by a consumer, returned or accepted by a public API, or a documented component. Internal helpers stay internal. |

## Adding a component

1. Put it in `Sources/LumiKitUI/Components/` (or `Controls/`, or the Photo / Debug / Lottie target it belongs to). Depend only on design tokens: `LMKColor`, `LMKTypography` (through `LMKTextStyle`), `LMKSpacing`, `LMKCornerRadius`, `LMKShadow`, `LMKAlpha`, `LMKLayout`. Never hard-code a color, font, spacing, radius, shadow, or alpha.
2. Give it a nested `Style` (see the naming table), a slot on `LMKTheme`, a nested `Strings` with keys in all four string tables (`en`, `es`, `zh-Hans`, `zh-Hant`), public structural subviews, a `didApplyStyle` hook, and `applyTheme(_:)` as the one place that assigns appearance. Call `lmk_startApplyingTheme()` at the end of `init` (views) or in `viewDidLoad` (view controllers).
3. Text goes through `lmk_apply(_:color:)` so it scales with Dynamic Type; fixed heights become floors (`greaterThanOrEqualTo`). Controls answer a 44pt hit area from `point(inside:with:)` and honor `isEnabled`. Animations check `LMKAnimation.shouldAnimate`.
4. Tests: a theme-change test, a Dynamic Type test, a layer re-stamp test for any `CGColor` sink, and behavior tests for the API. UIKit tests run on the simulator under `@MainActor`.
5. Add an Example page in the matching catalog section (`Example/Sources/Examples/`) and regenerate the project (`cd Example && xcodegen generate`).
6. Curate the new symbol in the target's DocC catalog (`Sources/<Target>/<Target>.docc`) and add a CHANGELOG entry.

## Localization

Every user-visible string is a key in `Sources/<Target>/Resources/<locale>.lproj/Localizable.strings`, read through `LMKLocalized(_:)`. Keys are `<component>.<element>` in lower camel case with `.accessibilityLabel`, `.accessibilityHint`, or `.accessibilityValue` suffixes for accessibility text; format arguments use `%@` / `%lld`, never string interpolation. A test per target checks that every key in `en` exists in the other three tables with a non-key value.

## Platform gates

New-OS APIs go behind `if #available(iOS 26, *)` with a fallback that keeps the same LumiKit API; see `docs/PLATFORM.md` for the list and the rules. The floor does not move for one feature.
