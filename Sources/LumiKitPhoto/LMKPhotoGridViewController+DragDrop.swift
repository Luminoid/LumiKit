//
//  LMKPhotoGridViewController+DragDrop.swift
//  LumiKit
//
//  Opt-in drag and drop for the photo grid: photos lift out as their file
//  or full image (`allowsDraggingPhotos`), and images dropped in arrive as
//  their original bytes (`onDropImages`).
//

import ImageIO
import LumiKitCore
import UIKit
import UniformTypeIdentifiers

// MARK: - Drag

extension LMKPhotoGridViewController: UICollectionViewDragDelegate {
    public func collectionView(_: UICollectionView, itemsForBeginning session: any UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        // Marks the session as this grid's, so its photos are not dropped back into it.
        session.localContext = self
        return dragItems(at: indexPath)
    }

    public func collectionView(_: UICollectionView, itemsForAddingTo _: any UIDragSession, at indexPath: IndexPath, point _: CGPoint) -> [UIDragItem] {
        dragItems(at: indexPath)
    }

    /// One drag item for the photo at `indexPath`: its file when the data source has one
    /// (`photoGridFileURL(at:)`), else a provider that loads the data source's full image when
    /// the destination asks for it. Empty while a pinch or a drag selection is under way, or
    /// when dragging is off.
    func dragItems(at indexPath: IndexPath) -> [UIDragItem] {
        guard allowsDraggingPhotos, pinchAnchor == nil, dragSelection == nil,
              let dsIndex = dataSourceIndex(forDisplayIndex: indexPath.item), let dataSource else { return [] }
        let provider = Self.fileProvider(for: dataSource.photoGridFileURL(at: dsIndex)) ?? imageProvider(at: dsIndex)
        let item = UIDragItem(itemProvider: provider)
        item.localObject = dsIndex
        return [item]
    }

    /// A provider for the image file at `url`, so the destination gets the original bytes,
    /// typed by what they hold; `nil` when `url` names no image file on disk.
    static func fileProvider(for url: URL?) -> NSItemProvider? {
        guard let url, url.isFileURL, let type = imageType(ofFileAt: url) else { return nil }
        let provider = NSItemProvider()
        provider.registerDataRepresentation(for: type, visibility: .all) { completion in
            do {
                try completion(Data(contentsOf: url), nil)
            } catch {
                completion(nil, error)
            }
            return nil
        }
        provider.suggestedName = url.deletingPathExtension().lastPathComponent
        return provider
    }

    /// The image type of the file at `url`, read from its header rather than its extension (a
    /// HEIC still saved as `.jpg` is HEIC); `nil` when the file is missing or not an image.
    static func imageType(ofFileAt url: URL) -> UTType? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil), let identifier = CGImageSourceGetType(source),
              let type = UTType(identifier as String), type.conforms(to: .image) else { return nil }
        return type
    }

    /// A provider that asks the data source for the full image when the destination loads it.
    /// It fails instead when the grid reloaded after the drag began: the index may name another
    /// photo by then.
    private func imageProvider(at dsIndex: Int) -> NSItemProvider {
        let provider = NSItemProvider()
        let generation = reloadGeneration
        provider.registerObject(ofClass: UIImage.self, visibility: .all) { [weak self] completion in
            Task { @MainActor [weak self] in
                guard let self, reloadGeneration == generation else {
                    LMKLogger.warning("LMKPhotoGridViewController: the grid reloaded during the drag, so the dragged photo was not delivered", category: .lumiKit)
                    completion(nil, CocoaError(.fileReadUnknown))
                    return
                }
                let image = await dataSource?.photoGridImage(at: dsIndex)
                if image == nil {
                    LMKLogger.warning("LMKPhotoGridViewController: the data source returned no image for the dragged photo at index \(dsIndex)", category: .lumiKit)
                }
                completion(image, image == nil ? CocoaError(.fileReadUnknown) : nil)
            }
            return nil
        }
        return provider
    }
}

// MARK: - Drop

extension LMKPhotoGridViewController: UICollectionViewDropDelegate {
    public func collectionView(_: UICollectionView, canHandle session: any UIDropSession) -> Bool {
        onDropImages != nil && session.hasItemsConforming(toTypeIdentifiers: [UTType.image.identifier])
    }

    public func collectionView(
        _: UICollectionView,
        dropSessionDidUpdate session: any UIDropSession,
        withDestinationIndexPath _: IndexPath?
    ) -> UICollectionViewDropProposal {
        // The grid sorts by date, so a drop has no position; a photo from this grid is already in it.
        guard onDropImages != nil, !isOwnDrag(session) else { return UICollectionViewDropProposal(operation: .cancel) }
        return UICollectionViewDropProposal(operation: .copy, intent: .unspecified)
    }

    public func collectionView(_: UICollectionView, performDropWith coordinator: any UICollectionViewDropCoordinator) {
        guard !isOwnDrag(coordinator.session) else { return }
        handleDrop(of: coordinator.items.map(\.dragItem.itemProvider))
    }

    /// Whether `session` started in this grid.
    func isOwnDrag(_ session: any UIDropSession) -> Bool {
        (session.localDragSession?.localContext as AnyObject?) === self
    }

    /// Loads the image bytes of every image provider and hands the ones that loaded to
    /// `onDropImages`, in drop order, once all have answered.
    func handleDrop(of providers: [NSItemProvider]) {
        let imageProviders = providers.filter { $0.hasItemConformingToTypeIdentifier(UTType.image.identifier) }
        guard !imageProviders.isEmpty else { return }
        // Each drop collects on its own: a drop still loading is the user's too, and keeps going.
        let collector = LMKPhotoGridDropCollector(count: imageProviders.count) { [weak self] images in
            self?.onDropImages?(images)
        }
        for (index, provider) in imageProviders.enumerated() {
            _ = provider.loadDataRepresentation(for: UTType.image) { data, error in
                if data == nil {
                    LMKLogger.warning("LMKPhotoGridViewController: a dropped image could not be read", error: error, category: .lumiKit)
                }
                Task { @MainActor in
                    collector.receive(data, at: index)
                }
            }
        }
    }
}

/// One drop's image loads, gathered on the main actor in drop order.
final class LMKPhotoGridDropCollector {
    private var results: [Data?]
    private var remaining: Int
    private let completion: ([Data]) -> Void

    init(count: Int, completion: @escaping ([Data]) -> Void) {
        results = Array(repeating: nil, count: count)
        remaining = count
        self.completion = completion
    }

    /// Records the load at `index` (`nil` = failed); the last answer delivers what loaded.
    func receive(_ data: Data?, at index: Int) {
        guard results.indices.contains(index), remaining > 0 else { return }
        results[index] = data
        remaining -= 1
        guard remaining == 0 else { return }
        let loaded = results.compactMap(\.self)
        if !loaded.isEmpty {
            completion(loaded)
        }
    }
}
