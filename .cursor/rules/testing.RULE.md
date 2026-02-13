---
description: "LumiKit testing patterns and conventions"
globs:
  - "**/*Tests.swift"
  - "**/Tests/**"
alwaysApply: false
---

# Testing Rules

## Test Structure

- **LumiKitCoreTests/**: 44 tests, 7 suites — pure Foundation tests
- **LumiKitUITests/**: 23 tests, 9 suites — UIKit component tests (requires iOS Simulator)

## Patterns

- **ALWAYS** use Arrange-Act-Assert pattern
- **ALWAYS** use descriptive names: `test[What]_[When]_[Expected]`
- **ALWAYS** use `@MainActor` for tests that touch UIKit or MainActor-isolated code
- **ALWAYS** add `// MARK: -` sections for logical grouping

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
