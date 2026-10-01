# ``LumiKitLottie``

A pull-to-refresh control driven by a Lottie animation, with the package's own ring animation bundled and tinted from the theme.

## Overview

`LumiKitLottie` is the only product that depends on Lottie, so apps that do not need it never link it. The control tracks the scroll view itself, honors Reduce Motion, and follows `theme.lottieRefreshControl` for its pull threshold, timeline, minimum spin, size, and tint.

```swift
import LumiKitLottie

let refresh = LMKLottieRefreshControl.install(on: tableView) { [weak self] in
    self?.reload()
}
// nil under the Mac idiom (UIRefreshControl is unsupported there); offer the key command instead:
addKeyCommand(LMKLottieRefreshControl.makeRefreshKeyCommand(action: #selector(reload)))
```

Pass `animation: LottieAnimation.named("spinner")` to use your own animation: it plays its own timeline, holding through the pull and looping from a `PHASE2_SPIN_LOOP` marker (or looping whole without one), unless `Style.timeline` says otherwise. Set `Style.appliesTint = false` to keep its colors. A refresh arms only while a finger is down and past the threshold, so a bounce or a programmatic offset never starts one; the ring re-tints on appearance and contrast changes and follows Reduce Motion at runtime.

## Topics

### Refresh control

- ``LMKLottieRefreshControl``
