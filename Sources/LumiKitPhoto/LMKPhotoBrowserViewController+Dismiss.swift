//
//  LMKPhotoBrowserViewController+Dismiss.swift
//  LumiKit
//
//  Overlay visibility, the swipe-to-dismiss progress, and dismissal of the
//  photo browser. The zoom transition is in `+Transition`.
//

import LumiKitUI
import UIKit

extension LMKPhotoBrowserViewController {
    // MARK: - Overlay

    func setOverlayAlpha(_ alpha: CGFloat) {
        dismissButton.alpha = alpha
        actionButton.alpha = alpha
        pageIndicator.alpha = alpha
        datePillView.alpha = alpha
        counterLabel.alpha = alpha
        // The pages' own chrome (the LIVE badge) goes with the browser's.
        for case let cell as LMKPhotoBrowserCell in collectionView.visibleCells {
            cell.chromeAlpha = alpha
        }
    }

    func toggleOverlay(animated: Bool) {
        isOverlayHidden.toggle()
        let visible = !isOverlayHidden
        let duration = (animated && LMKAnimation.shouldAnimate) ? LMKAnimation.Duration.normal : 0
        UIView.animate(withDuration: duration, delay: 0, options: .curveEaseInOut) { [weak self] in
            self?.setOverlayAlpha(visible ? 1 : 0)
        }
        dismissButton.isUserInteractionEnabled = visible
        actionButton.isUserInteractionEnabled = visible
        pageIndicator.isUserInteractionEnabled = visible
    }

    // MARK: - Dismissal

    /// Reports the dismissal to the delegate and `onDismiss`, then dismisses. With a zoom
    /// source the photo travels back to it while the stage and chrome clear.
    func dismissBrowser() {
        notifyDismiss()
        dismiss(animated: true)
    }

    private func notifyDismiss() {
        delegate?.photoBrowserDidDismiss(self)
        onDismiss?()
    }

    /// Commits a swipe from where the drag left the photo: with a zoom source the photo
    /// travels back to it; otherwise it shrinks and fades. The stage never returns to opaque
    /// on the way out.
    func performDismissWithSnapTiming(from cell: LMKPhotoBrowserCell? = nil) {
        (cell ?? currentCell)?.freezeForDismissal()
        if zoomSourceView != nil {
            notifyDismiss()
            dismiss(animated: true)
            return
        }
        let duration = LMKAnimation.shouldAnimate ? LMKAnimation.Duration.fast : 0
        let snapScale = LMKPhotoBrowserMetrics.dismissSnapScale
        UIView.animate(withDuration: duration, delay: 0, options: [.curveEaseOut, .allowUserInteraction, .beginFromCurrentState]) { [weak self] in
            self?.stageView.alpha = 0
            self?.collectionView.alpha = 0
            self?.setOverlayAlpha(0)
            self?.collectionView.transform = CGAffineTransform(scaleX: snapScale, y: snapScale)
        } completion: { [weak self] _ in
            guard let self else { return }
            notifyDismiss()
            dismiss(animated: false)
        }
    }

    /// Drives the stage alpha and page scale from a vertical drag: progress 0 (no drag) to 1
    /// (at the dismiss threshold); 0 animates everything back. Only the stage fades, so the
    /// screen underneath shows through while the photo stays solid.
    public func updateDismissProgress(_ progress: CGFloat) {
        if progress > 0 {
            stageView.alpha = Self.stageAlpha(progress: progress, minimumAlpha: resolvedStyle.dismissFloorAlpha)
            let scale = 1 - min(progress, 1) * resolvedStyle.dismissScaleEffect
            collectionView.transform = CGAffineTransform(scaleX: scale, y: scale)
            if !isOverlayHidden {
                setOverlayAlpha(Self.overlayAlpha(progress: progress))
            }
        } else {
            let duration = LMKAnimation.shouldAnimate ? LMKAnimation.Duration.normal : 0
            UIView.animate(withDuration: duration, delay: 0, options: [.curveEaseOut, .beginFromCurrentState]) { [weak self] in
                guard let self else { return }
                stageView.alpha = 1
                collectionView.transform = .identity
                if !isOverlayHidden {
                    setOverlayAlpha(1)
                }
            }
        }
    }

    // MARK: - Pure helpers

    /// Stage alpha for a drag `progress`: opaque for the first bit of the drag, then clearing
    /// steadily until it reaches `minimumAlpha` at the dismiss threshold. It never rises while
    /// the drag goes further.
    nonisolated static func stageAlpha(progress: CGFloat, minimumAlpha: CGFloat) -> CGFloat {
        let start = LMKPhotoBrowserMetrics.dismissOpacityStartThreshold
        let opacityProgress = min(1, max(0, (progress - start) / (1 - start)))
        return 1 - opacityProgress * (1 - min(max(minimumAlpha, 0), 1))
    }

    /// Overlay alpha for a drag `progress`: the chrome clears out faster than the stage.
    nonisolated static func overlayAlpha(progress: CGFloat) -> CGFloat {
        max(0, 1 - progress * LMKPhotoBrowserMetrics.overlayFadeMultiplier)
    }

    /// The vertical distance a drag must cover to dismiss a page of `height`.
    nonisolated static func verticalDismissThreshold(pageHeight: CGFloat) -> CGFloat {
        max(LMKPhotoBrowserMetrics.verticalDismissMinimumPoints, pageHeight * LMKPhotoBrowserMetrics.verticalDismissThresholdFraction)
    }

    /// Whether a released drag dismisses: past the distance threshold, or a flick that already
    /// covered the minimum distance.
    nonisolated static func shouldDismiss(offset: CGFloat, velocity: CGFloat, threshold: CGFloat) -> Bool {
        let distanceReached = abs(offset) >= threshold
        let velocityReached = abs(velocity) >= LMKPhotoBrowserMetrics.verticalDismissVelocityThreshold
            && abs(offset) >= LMKPhotoBrowserMetrics.verticalDismissMinimumDistanceForVelocity
        return distanceReached || velocityReached
    }
}
