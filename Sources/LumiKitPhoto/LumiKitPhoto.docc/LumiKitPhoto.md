# ``LumiKitPhoto``

A photo browser, a photo grid, a crop editor, a pick-and-crop coordinator, a share preview, and image metadata, built on `LumiKitUI`.

## Overview

Link `LumiKitPhoto` only in targets that show photos; it is the product that depends on PhotosUI. Every view controller has a `Style` with a slot on the theme (`theme.photoBrowser`, `theme.photoGrid`, `theme.photoCrop`, `theme.sharePreview`), a `Strings` struct with localized defaults, and `on<Event>` closures next to the multi-method data sources and delegates.

```swift
import LumiKitPhoto

let browser = LMKPhotoBrowserViewController(initialIndex: 2)
browser.dataSource = source
browser.delegate = self
browser.zoomSourceView = { [weak self] index in self?.thumbnail(at: index) }   // the photo zooms out of its thumbnail
browser.onDismiss = { ... }
present(browser, animated: true)

let metadata = await LMKPhotoMetadata.read(from: pickerResult)
```

The browser presents over the full screen, so the screen it came from stays underneath: a drag up or down moves the photo with the finger and fades the stage to that screen, and letting go past the threshold dismisses (the photo zooms back to `zoomSourceView` when there is one). Opening and closing move only the photo: the screen underneath holds still. Set `modalPresentationStyle = .fullScreen` to take the presenter out of the hierarchy; the drag then plays over black.

Images load through async data-source requirements (`photo(at:)`, `photoGridImage(at:)`): decode off the main actor and return a ready-to-display image; both hosts show a placeholder while loading and drop results that arrive after a cell was reused. The browser and crop editor force dark mode and manage the status bar; embed them in a navigation controller only with `childForStatusBarStyle` forwarded.

## Topics

### Browsing and grids

- ``LMKPhotoBrowserViewController``
- ``LMKPhotoBrowserDataSource``
- ``LMKPhotoBrowserDelegate``
- ``LMKSinglePhotoViewer``
- ``LMKPhotoGridViewController``
- ``LMKPhotoGridDataSource``
- ``LMKPhotoGridDelegate``

### Cropping and picking

- ``LMKPhotoCropViewController``
- ``LMKCropAspectRatio``
- ``LMKPhotoPickCropCoordinator``

### Sharing and metadata

- ``LMKSharePreviewViewController``
- ``LMKPhotoMetadata``
