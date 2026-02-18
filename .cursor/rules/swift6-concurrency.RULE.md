---
description: "Swift 6.2 strict concurrency patterns for LumiKit"
alwaysApply: true
---

# Swift 6.2 Concurrency

## Target-Level Default Isolation

LumiKitUI and LumiKitLottie set `defaultIsolation: MainActor` in `Package.swift`. This means:

- **All types** in these targets are implicitly `@MainActor` — no explicit annotation needed
- **Do NOT** add `@MainActor` to UIViewController subclasses, views, or components in LumiKitUI/Lottie — it is redundant
- **LumiKitCore** has no default isolation — types are `nonisolated` by default

## Opting Out of MainActor

When a type in LumiKitUI must be callable from any isolation context, use:

```swift
// nonisolated enum (utility type, no mutable state)
public nonisolated enum LMKImageUtil { ... }

// nonisolated struct (data type, Sendable)
public nonisolated struct LMKSpacingTheme: Sendable { ... }
```

- **ALWAYS** use `nonisolated struct: Sendable` for theme config structs
- **ALWAYS** use `nonisolated enum` for static utility types that should be callable off-main

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
- Two naming patterns in codebase: top-level `LMK*Strings` or nested `Type.Strings`

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
