//
//  LMKPhotoBrowserViewController+MacCatalyst.swift
//  LumiKit
//
//  Mac Catalyst behaviors of the photo browser: scroll indicators and
//  scroll-wheel paging. Key commands live on the controller itself, since
//  hardware keyboards exist on iPad too.
//

import UIKit

extension LMKPhotoBrowserViewController {
    /// Installs the Mac-only behaviors; a no-op on other platforms.
    func installMacBehaviors() {
        #if targetEnvironment(macCatalyst)
            collectionView.showsHorizontalScrollIndicator = true
            collectionView.showsVerticalScrollIndicator = true

            // Discrete scroll-wheel events page; continuous pans stay with the collection view.
            let scrollWheel = UIPanGestureRecognizer(target: self, action: #selector(handleScrollWheel(_:)))
            scrollWheel.allowedScrollTypesMask = .discrete
            scrollWheel.delegate = scrollWheelDelegate
            scrollWheel.cancelsTouchesInView = false
            collectionView.addGestureRecognizer(scrollWheel)
        #endif
    }
}

#if targetEnvironment(macCatalyst)
    private extension LMKPhotoBrowserViewController {
        @objc func handleScrollWheel(_ gesture: UIPanGestureRecognizer) {
            guard gesture.state == .ended else { return }
            let velocity = gesture.velocity(in: collectionView)
            let threshold = LMKPhotoBrowserMetrics.scrollWheelVelocityThreshold
            // A scroll toward the next page (to the left; to the right in a right-to-left layout).
            let step = isRightToLeft ? -1 : 1
            if velocity.x < -threshold {
                showPhoto(at: currentIndex + step, animated: true)
            } else if velocity.x > threshold {
                showPhoto(at: currentIndex - step, animated: true)
            }
        }
    }

    /// Gesture delegate of the scroll-wheel recognizer, kept off the public surface.
    final class LMKPhotoBrowserScrollWheelDelegate: NSObject, UIGestureRecognizerDelegate {
        private weak var collectionView: UICollectionView?

        init(collectionView: UICollectionView) {
            self.collectionView = collectionView
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            true
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            if otherGestureRecognizer is UIPinchGestureRecognizer {
                return true
            }
            // The collection view's own pan runs first.
            return otherGestureRecognizer is UIPanGestureRecognizer && otherGestureRecognizer.view === collectionView
        }

        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            guard let pan = gestureRecognizer as? UIPanGestureRecognizer else { return true }
            return pan.allowedScrollTypesMask.contains(.discrete)
        }
    }
#endif
