---
description: "LumiKit naming conventions: LMK prefix for public types, lmk_ for extensions"
alwaysApply: true
---

# Naming Conventions

## Public Types — LMK Prefix

- **ALWAYS** prefix public types with `LMK`: `LMKColor`, `LMKSpacing`, `LMKAnimationHelper`
- **ViewControllers**: `LMK*ViewController` (e.g. `LMKPhotoBrowserViewController`)
- **Cells**: `LMK*Cell` (e.g. `LMKPhotoBrowserCell`, `LMKSkeletonCell`)
- **Protocols**: `LMK*DataSource`, `LMK*Delegate` (e.g. `LMKPhotoBrowserDataSource`)
- **Helpers/Utils**: `LMK*Helper`, `LMK*Util` (e.g. `LMKDateHelper`, `LMKFileUtil`)
- **Enums**: `LMK*` (e.g. `LMKConcurrencyHelpers`, `LMKAlpha`)
- **Theme configs**: `LMK*Theme` (e.g. `LMKTypographyTheme`, `LMKSpacingTheme`)

## Configurable Strings — Two Patterns

Both patterns exist in the codebase:

1. **Top-level struct** with module-level var (for standalone components):
   ```swift
   public struct LMKPhotoCropStrings: Sendable { ... }
   nonisolated(unsafe) public var lmkPhotoCropStrings = LMKPhotoCropStrings()
   ```

2. **Nested struct** inside the component (for components with few strings):
   ```swift
   public final class LMKSearchBar: UIView {
       public struct Strings: Sendable { ... }
       nonisolated(unsafe) public static var strings = Strings()
   }
   ```

## Extension Methods — lmk_ Prefix

- **ALWAYS** prefix public extension methods with `lmk_`: `view.lmk_addSubviews(...)`
- **File naming**: `UIView+LMKLayout.swift`, `UIButton+LMKAnimation.swift`
- **Category grouping**: one extension file per feature area, not per method
- **Multi-type files**: If a file contains extensions on multiple related types (e.g., `UITextField` and `UITextView`), name for the primary type or use a generic name

## File Naming

- **Domain-specific names**: `LMKDateHelper.swift` not `DateHelper.swift`
- **Extensions**: `{Type}+LMK{Feature}.swift` (e.g. `String+LMK.swift`, `UIView+LMKFade.swift`)
- **One public type per file** (matching the file name)
- **Utility enums** (static-only types): `LMK*Util` or `LMK*Helper` (e.g. `LMKImageUtil`, `LMKSceneUtil`)
