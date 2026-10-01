---
description: "Swift 6.2 / 6.4 strict concurrency patterns for LumiKit"
alwaysApply: true
---

# Swift 6 Concurrency

## Target-Level Default Isolation

LumiKitUI, LumiKitPhoto, and LumiKitLottie set `defaultIsolation: MainActor` in `Package.swift`:

- **All types** in these targets are implicitly `@MainActor`; **do NOT** add `@MainActor` to views, view controllers, or components
- **LumiKitCore** and **LumiKitDebug** have no default isolation; their types are `nonisolated` by default
- **Swift 6.4 (Xcode 27)**: the members of an `extension` follow the module's default actor even when the extended type is nonisolated, so an extension meant to run anywhere (`UIImage`, `LMKTheme` style slots, protocol defaults) is a `nonisolated extension` and gets a case in `LMKNonisolatedSurfaceTests`; a subclass of a package controller declares `isolated deinit`

## Opting Out of MainActor

```swift
public nonisolated struct LMKSpacingTheme: Sendable, Equatable { ... }   // configuration value
public nonisolated enum LMKStatus: Sendable, Hashable, CaseIterable { ... }
public nonisolated enum LMKImage { ... }                                  // static utility callable off-main
@concurrent nonisolated static func downsample(...) async -> UIImage?    // work that must leave the main actor
```

- **ALWAYS** make theme category structs, `Style` structs, `Strings` structs, and public enums `nonisolated` + `Sendable` (`Equatable` / `Hashable` as appropriate)
- **ALWAYS** use `@concurrent nonisolated static func` for CPU work (image decoding, cropping, color extraction); a sync and an async overload of one name resolve by context, so the async body must not call itself by name
- Token reads (`LMKColor.primary`, `LMKSpacing.large`, `LMKTheme.current`) are `nonisolated`; only `LMKTheme.apply` / `update` / `reset` are `@MainActor`

## Shared State

- **ALWAYS** guard process-wide mutable state in Core with a lock: `Mutex` (`LMKLogger`, `LMKDate`, `LMKLogStore`) or `NSLock` (`LMKDateFormat.strings`); `nonisolated(unsafe)` is reserved for a `static let` observer token Swift cannot prove Sendable and for the `static var strings` defaults below
- **NEVER** `nonisolated(unsafe) static var` for configuration that is mutated after launch while other threads read it

## Strings

- Every configurable string is a nested `Strings: Sendable, Equatable` struct with `LMKLocalized` defaults, a `nonisolated(unsafe) static var strings` process-wide default (written once at launch before any read; Core guards its copy with a lock), and an instance `strings` on host-created types; see `naming.RULE.md`

## Tasks and Hops

- **Every `Task { }` stores its handle** in a property and is cancelled in `deinit` (`Task` handles are Sendable; observer tokens and `DispatchWorkItem`s are not, so keep those out of `deinit`)
- **ALWAYS** use `LMKConcurrency.encode` / `decode` (throwing, custom coders) for Codable work from any isolation
- **ALWAYS** use `LMKConcurrency.onMainActor(weak:_:)` / `onMainActorAfter(delay:_:)` (both return the `Task`) instead of `DispatchQueue.main.async` / `asyncAfter`
- **ALWAYS** use `LMKConcurrency.executeTask(weak:operation:)` for view-controller tasks that need cancellation and error logging
- `LMKConcurrency.assertMainActor(operation:)` wraps `MainActor.assertIsolated`
