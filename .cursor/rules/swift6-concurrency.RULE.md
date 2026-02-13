---
description: "Swift 6 strict concurrency patterns for LumiKit"
alwaysApply: true
---

# Swift 6 Concurrency

## @MainActor

- **ALWAYS** mark UIViewController subclasses with `@MainActor`
- **ALWAYS** mark `LMKThemeManager` and similar singletons with `@MainActor`
- **NEVER** nest configurable strings inside `@MainActor` classes — they must be module-level

## Configurable Strings Pattern

**ALWAYS** use this pattern for user-facing strings that apps can override:

```swift
// 1. Sendable struct with defaults
public struct LMKFeatureStrings: Sendable {
    public var title: String
    public init(title: String = "Default") {
        self.title = title
    }
}

// 2. Module-level nonisolated(unsafe) var
nonisolated(unsafe) public var lmkFeatureStrings = LMKFeatureStrings()
```

- **MUST** be `Sendable` — all stored properties must be `Sendable`
- **MUST** use `nonisolated(unsafe)` at module level — not inside a class
- **MUST** provide reasonable defaults in `init`
- Apps set strings once at launch before any UI runs

## Sendable

- **ALWAYS** make configuration structs `Sendable`
- **ALWAYS** make protocols `Sendable` when their conformers are shared across actors
- `LMKTheme` protocol is `Sendable` (theme values are read from multiple contexts)

## Concurrency Helpers

- **ALWAYS** use `LMKConcurrencyHelpers.encode/decode` for off-main-thread Codable operations
- **ALWAYS** use `LMKConcurrencyHelpers.executeTask(weak:)` for async tasks in ViewControllers
- **ALWAYS** use `LMKConcurrencyHelpers.assertMainActor(operation:)` for runtime safety checks
- **NEVER** use `DispatchQueue.main.async` — use `LMKConcurrencyHelpers.onMainActor(weak:)` instead
- **NEVER** use `DispatchQueue.main.asyncAfter` — use `LMKConcurrencyHelpers.onMainActorAfter(delay:)` instead
