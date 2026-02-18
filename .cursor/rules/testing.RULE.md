---
description: "LumiKit testing patterns and conventions"
globs:
  - "**/*Tests.swift"
  - "**/Tests/**"
alwaysApply: false
---

# Testing Rules

## Test Structure

- **LumiKitCoreTests/**: 56 tests, 9 suites — pure Foundation tests (mirrors Sources/LumiKitCore/ subfolders)
- **LumiKitUITests/**: 178 tests, 51 suites — UIKit component tests (requires iOS Simulator, mirrors Sources/LumiKitUI/ subfolders)
- **LumiKitLottie**: No test target — manual verification only

## Framework: Swift Testing

The entire test suite uses **Swift Testing** (not XCTest):

- **ALWAYS** use `@Suite("Description")` for test suites
- **ALWAYS** use `@Test("description") func camelCaseName()` for test methods
- **ALWAYS** use `#expect(...)` for assertions
- **ALWAYS** use `try #require(...)` for unwrapping optionals (never force unwrap `!` in tests)
- **ALWAYS** use `@MainActor` on suites/tests that touch UIKit or MainActor-isolated code

## Patterns

- **ALWAYS** use Arrange-Act-Assert pattern
- **ALWAYS** add `// MARK: -` sections for logical grouping
- **ALWAYS** use `.serialized` trait on suites that mutate shared state (e.g., `LMKThemeManager.shared`, configurable strings)
- **ALWAYS** use `defer` to restore shared state after mutation:
  ```swift
  @Test("custom theme") func customTheme() {
      LMKThemeManager.shared.apply(spacing: .init(large: 20))
      defer { LMKThemeManager.shared.apply(spacing: .init()) }
      #expect(LMKSpacing.large == 20)
  }
  ```
- **ALWAYS** test real behavior — assert meaningful properties, not just "no crash"
- **ALWAYS** test edge cases: empty strings, nil values, zero sizes, negative values, boundary conditions

## Build & Test Commands

```bash
# Run all tests (requires iOS Simulator — can't use swift test for UIKit targets)
xcodebuild test \
  -scheme LumiKit-Package \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -skipPackagePluginValidation \
  CODE_SIGNING_ALLOWED=NO 2>&1 | tail -20

# Build only (faster, no simulator needed for Core)
swift build --target LumiKitCore
```

- **NEVER** use `swift test` for the full package — UIKit targets require iOS Simulator
- `swift build --target LumiKitCore` is fine for Core-only changes (no UIKit)

## Target-Specific Testing

- **LumiKitCore**: Can test with `swift test` if needed (pure Foundation)
- **LumiKitUI**: Must use `xcodebuild test` with iOS Simulator
- **LumiKitLottie**: No test target currently — manual verification
