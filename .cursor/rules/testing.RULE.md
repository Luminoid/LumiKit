---
description: "LumiKit testing patterns and conventions"
globs:
  - "**/*Tests.swift"
  - "**/Tests/**"
alwaysApply: false
---

# Testing Rules

## Structure

Five test targets mirror the source folders: `LumiKitCoreTests`, `LumiKitUITests` (with `Support/` for `LMKThemeTesting` and `LMKWait`, and `Naming/` for the naming-rule scan), `LumiKitPhotoTests`, `LumiKitDebugTests`, `LumiKitLottieTests`. Every UIKit target needs the iOS Simulator; `swift test` cannot run the package.

## Framework: Swift Testing

- **ALWAYS** `@Suite("Description")` (or a plain struct) and `@Test func \`readable name\`()`; `#expect(...)`; `try #require(...)` instead of force unwraps
- **ALWAYS** `@MainActor` on suites that touch UIKit or main-actor code
- **ALWAYS** `.serialized` on suites that mutate shared state (`LMKTheme.apply`, `Type.strings`, `LMKLogger` configuration, `LMKHaptics.isEnabled`) and restore it with `defer`
- **ALWAYS** Arrange-Act-Assert, `// MARK: -` sections, real behavior assertions (not just "no crash"), edge cases (empty, nil, zero, negative, boundary)

## Theme and Layout Helpers

```swift
let traits = LMKThemeTesting.traits(for: LMKThemeTesting.distinct, style: .dark, contrast: .high)
let view = LMKChipView(text: "x")
view.traitOverrides.lmkTheme = LMKThemeReference(LMKThemeTesting.distinct)   // per-view scoping, no global mutation
LMKThemeTesting.fit(view, width: 320)                                          // lays out at a width
await LMKWait.until { toast.isPresented }                                      // poll instead of a fixed sleep
```

- Per component: a theme-change test, a Dynamic Type test (`traitOverrides.preferredContentSizeCategory = .accessibilityExtraExtraExtraLarge`), a layer re-stamp test (`traitOverrides.userInterfaceStyle = .dark` re-resolves `layer.shadowColor`), and behavior tests
- The xctest host has no connected scene: `LMKTheme.apply` cannot stamp test windows; stamp `LMKTheme.currentReference` by hand

## xctest-Host Gotchas

- `UIControl.sendActions(for:)` delivers nothing: call the handler or the `on*` closure directly
- UIKit modal `present` / `dismiss` completions never run, and UIKit keeps a dismissed alert alive, so an awaited `LMKAlert.confirm` dismissed programmatically never resumes in the host (test the continuation helper instead); `UIRefreshControl.isRefreshing` never turns true; `becomeFirstResponder()` on a view controller hangs; `UIPasteboard.general` blocks forever
- `accessibilityPerformEscapeBlock`'s getter raises `unrecognized selector` in the host: components answer the escape gesture by overriding `accessibilityPerformEscape()` on a view subclass
- iOS 26.2: a `UISlider` whose `trackConfiguration` is set back to `nil` ignores every later `value` (pinned to the minimum); replace a published configuration with a plain one instead of clearing it
- `UIView.setAnimationsEnabled` is process-global and unsafe across parallel suites; parallel suites can hold the main actor for seconds, so wait with `LMKWait.until` and a deadline
- Trait overrides propagate only inside a window; reading `traitOverrides` without an override traps
- Compare `CGFloat`s against a single literal (`#expect(x == 351)`), not an `Int` expression

## Commands

```bash
make test                                                   # full package, iPhone 17 simulator
make test-filter FILTER=LumiKitUITests/LMKButtonTests       # one suite (append /methodName for one test)
make build-host                                             # LumiKitCore + LumiKitDebug natively (build only)
```

Logs land in `build/logs/`; read the log for the result rather than a piped exit code.
