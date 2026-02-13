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
- **Configurable strings structs**: `LMK*Strings` (e.g. `LMKPhotoCropStrings`)
- **Helpers/Utils**: `LMK*Helper`, `LMK*Util` (e.g. `LMKDateHelper`, `LMKFileUtil`)
- **Enums**: `LMK*` (e.g. `LMKConcurrencyHelpers`, `LMKAlpha`)

## Extension Methods — lmk_ Prefix

- **ALWAYS** prefix public extension methods with `lmk_`: `view.lmk_addSubviews(...)`
- **File naming**: `UIView+LMKLayout.swift`, `UIButton+LMKAnimation.swift`
- **Category grouping**: one extension file per feature area, not per method

## File Naming

- **Domain-specific names**: `LMKDateHelper.swift` not `DateHelper.swift`
- **Extensions**: `{Type}+LMK{Feature}.swift` (e.g. `String+LMK.swift`, `UIView+LMKFade.swift`)
- **One public type per file** (matching the file name)
