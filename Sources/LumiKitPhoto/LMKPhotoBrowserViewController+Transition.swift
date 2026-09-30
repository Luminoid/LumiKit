//
//  LMKPhotoBrowserViewController+Transition.swift
//  LumiKit
//
//  The browser's own presentation and dismissal when it has a zoom source:
//  the photo travels between its thumbnail and its place on the stage while
//  the stage fades. The screen underneath does not move (the system zoom
//  transition scales the whole presenting screen down and back).
//

import LumiKitUI
import UIKit

// MARK: - Transitioning delegate

extension LMKPhotoBrowserViewController: UIViewControllerTransitioningDelegate {
    /// Installs the photo transition while there is a zoom source; the plain modal transition otherwise.
    func updateTransition() {
        transitioningDelegate = zoomSourceView == nil ? nil : self
    }

    public func animationController(forPresented _: UIViewController, presenting _: UIViewController, source _: UIViewController) -> (any UIViewControllerAnimatedTransitioning)? {
        LMKPhotoBrowserZoomAnimator(browser: self, direction: .present)
    }

    public func animationController(forDismissed _: UIViewController) -> (any UIViewControllerAnimatedTransitioning)? {
        LMKPhotoBrowserZoomAnimator(browser: self, direction: .dismiss)
    }
}

// MARK: - Animator

/// Moves one photo between its source view and the browser's stage.
final class LMKPhotoBrowserZoomAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    enum Direction {
        case present
        case dismiss
    }

    /// What the travelling photo shows and where its thumbnail sits.
    struct Source {
        let view: UIView
        let image: UIImage?
        /// The thumbnail's frame in the transition container.
        let frame: CGRect
        let cornerRadius: CGFloat
    }

    private weak var browser: LMKPhotoBrowserViewController?
    private let direction: Direction

    init(browser: LMKPhotoBrowserViewController, direction: Direction) {
        self.browser = browser
        self.direction = direction
    }

    func transitionDuration(using _: (any UIViewControllerContextTransitioning)?) -> TimeInterval {
        LMKAnimation.shouldAnimate ? LMKAnimation.Duration.slow : LMKAnimation.Duration.fast
    }

    func animateTransition(using context: any UIViewControllerContextTransitioning) {
        guard let browser else {
            context.completeTransition(!context.transitionWasCancelled)
            return
        }
        switch direction {
        case .present: animatePresentation(of: browser, using: context)
        case .dismiss: animateDismissal(of: browser, using: context)
        }
    }

    /// A fade of `view` to `alpha`, for the paths with no thumbnail to travel to or from.
    private func makeFade(of view: UIView, to alpha: CGFloat, using context: any UIViewControllerContextTransitioning) -> UIViewPropertyAnimator {
        UIViewPropertyAnimator(duration: transitionDuration(using: context), curve: .easeOut) {
            view.alpha = alpha
        }
    }

    // MARK: Presentation

    private func animatePresentation(of browser: LMKPhotoBrowserViewController, using context: any UIViewControllerContextTransitioning) {
        let container = context.containerView
        let browserView: UIView = context.view(forKey: .to) ?? browser.view
        browserView.frame = context.finalFrame(for: browser)
        container.addSubview(browserView)
        browserView.layoutIfNeeded()

        let overlayAlpha: CGFloat = browser.isOverlayHidden ? 0 : 1
        browser.stageView.alpha = 0
        browser.setOverlayAlpha(0)

        guard LMKAnimation.shouldAnimate, let source = Self.source(for: browser, in: container), let image = source.image else {
            // No thumbnail to leave from (or Reduce Motion): the browser fades in.
            browserView.alpha = 0
            browser.stageView.alpha = 1
            browser.setOverlayAlpha(overlayAlpha)
            let fade = makeFade(of: browserView, to: 1, using: context)
            fade.addCompletion { _ in context.completeTransition(!context.transitionWasCancelled) }
            fade.startAnimation()
            return
        }

        let target = Self.stageFrame(for: image, of: browser, in: container)
        let stageColor = browser.resolvedStyle.stageColor
        // A see-through photo leaves its thumbnail looking as it did there, and gains the stage's backing on the way.
        let photo = Self.makeTravellingPhoto(image: image, frame: source.frame, cornerRadius: source.cornerRadius, backing: .clear, browser: browser)
        container.addSubview(photo)
        let sourceAlpha = source.view.alpha
        source.view.alpha = 0
        // Out of sight but still in touch: an empty mask hides the pages without taking them out of hit testing.
        browser.collectionView.mask = UIView()
        // UIKit delivers no touches until a transition is over, and a swipe made right after the
        // tap would be lost. Over the full screen nothing else waits on the transition (the
        // presenter stays where it is), so it ends at once and the photo finishes its way alone.
        let endsTransitionAtOnce = context.view(forKey: .from) == nil

        let animator = UIViewPropertyAnimator(duration: transitionDuration(using: context), dampingRatio: 1) {
            photo.frame = target
            photo.layer.cornerRadius = 0
            photo.backgroundColor = stageColor
            browser.stageView.alpha = 1
            browser.setOverlayAlpha(overlayAlpha)
        }
        animator.addCompletion { _ in
            source.view.alpha = sourceAlpha
            browser.collectionView.mask = nil
            // The page takes over under the travelling photo, which then clears: a page whose
            // photo is still loading, or has another shape, comes in without a jump.
            UIView.animate(withDuration: LMKAnimation.Duration.fast, delay: 0, options: .curveEaseOut) {
                photo.alpha = 0
            } completion: { _ in
                photo.removeFromSuperview()
            }
            if !endsTransitionAtOnce {
                context.completeTransition(!context.transitionWasCancelled)
            }
        }
        animator.startAnimation()
        if endsTransitionAtOnce {
            context.completeTransition(true)
        }
    }

    // MARK: Dismissal

    private func animateDismissal(of browser: LMKPhotoBrowserViewController, using context: any UIViewControllerContextTransitioning) {
        let container = context.containerView
        let browserView: UIView = context.view(forKey: .from) ?? browser.view
        if let presenterView = context.view(forKey: .to) {
            // A full-screen presentation took the presenter out; it comes back under the browser.
            presenterView.frame = context.finalFrame(for: context.viewController(forKey: .to) ?? browser)
            container.insertSubview(presenterView, belowSubview: browserView)
        }

        let cell = browser.currentCell
        let start = cell?.photoFrame(in: container)
        guard LMKAnimation.shouldAnimate, let start, let source = Self.source(for: browser, in: container),
              let image = cell?.displayedImage ?? source.image
        else {
            // Nothing to fly back to (the thumbnail scrolled away, or Reduce Motion): the browser fades out.
            let fade = makeFade(of: browserView, to: 0, using: context)
            fade.addCompletion { _ in Self.finishDismissal(of: browserView, using: context) }
            fade.startAnimation()
            return
        }

        let photo = Self.makeTravellingPhoto(image: image, frame: start, cornerRadius: 0, backing: browser.resolvedStyle.stageColor, browser: browser)
        container.addSubview(photo)
        let sourceAlpha = source.view.alpha
        source.view.alpha = 0
        browser.collectionView.alpha = 0

        let animator = UIViewPropertyAnimator(duration: transitionDuration(using: context), dampingRatio: 1) {
            photo.frame = source.frame
            photo.layer.cornerRadius = source.cornerRadius
            photo.backgroundColor = .clear
            browser.stageView.alpha = 0
            browser.setOverlayAlpha(0)
        }
        animator.addCompletion { _ in
            source.view.alpha = sourceAlpha
            photo.removeFromSuperview()
            Self.finishDismissal(of: browserView, using: context)
        }
        animator.startAnimation()
    }

    private static func finishDismissal(of browserView: UIView, using context: any UIViewControllerContextTransitioning) {
        let finished = !context.transitionWasCancelled
        if finished {
            browserView.removeFromSuperview()
        }
        context.completeTransition(finished)
    }

    // MARK: Geometry

    /// The current photo's thumbnail, when it is on screen.
    static func source(for browser: LMKPhotoBrowserViewController, in container: UIView) -> Source? {
        guard let view = browser.zoomSourceView?(browser.currentPhotoIndex), view.window != nil, !view.isHidden else { return nil }
        let imageView = view as? UIImageView ?? firstImageView(in: view)
        guard let imageView, let image = imageView.image else {
            let frame = view.convert(view.bounds, to: container)
            guard frame.width > 0, frame.height > 0, container.bounds.intersects(frame) else { return nil }
            return Source(view: view, image: snapshot(of: view), frame: frame, cornerRadius: view.layer.cornerRadius)
        }
        let drawn = imageView.contentMode == .scaleAspectFit ? aspectFit(image.size, in: imageView.bounds) : imageView.bounds
        let frame = imageView.convert(drawn, to: container)
        guard frame.width > 0, frame.height > 0, container.bounds.intersects(frame) else { return nil }
        let radius = imageView.layer.cornerRadius > 0 ? imageView.layer.cornerRadius : view.layer.cornerRadius
        return Source(view: view, image: image, frame: frame, cornerRadius: imageView.contentMode == .scaleAspectFit ? 0 : radius)
    }

    /// Where `image` sits on the browser's stage at 1x: the current page's photo when it is
    /// already laid out, else the fit the page will give it.
    static func stageFrame(for image: UIImage, of browser: LMKPhotoBrowserViewController, in container: UIView) -> CGRect {
        if let frame = browser.currentCell?.photoFrame(in: container) {
            return frame
        }
        let bounds = browser.view.convert(browser.view.bounds, to: container)
        return aspectFit(image.size, in: bounds)
    }

    /// `size` scaled to fit `bounds`, centered (the browser page's fit).
    nonisolated static func aspectFit(_ size: CGSize, in bounds: CGRect) -> CGRect {
        guard size.width > 0, size.height > 0 else { return bounds }
        let fitted = LMKPhotoBrowserCell.fittedSize(imageSize: size, in: bounds.size)
        return CGRect(x: bounds.midX - fitted.width / 2, y: bounds.midY - fitted.height / 2, width: fitted.width, height: fitted.height)
    }

    private static func makeTravellingPhoto(image: UIImage, frame: CGRect, cornerRadius: CGFloat, backing: UIColor, browser: LMKPhotoBrowserViewController) -> UIImageView {
        let photo = UIImageView(image: image)
        photo.contentMode = .scaleAspectFill
        photo.clipsToBounds = true
        photo.frame = frame
        photo.layer.cornerRadius = cornerRadius
        photo.layer.cornerCurve = .continuous
        photo.backgroundColor = backing
        photo.preferredImageDynamicRange = browser.effectiveDynamicRange
        return photo
    }

    private static func firstImageView(in view: UIView) -> UIImageView? {
        var queue = view.subviews
        while !queue.isEmpty {
            let next = queue.removeFirst()
            if let imageView = next as? UIImageView, imageView.image != nil, !imageView.isHidden {
                return imageView
            }
            queue.append(contentsOf: next.subviews)
        }
        return nil
    }

    private static func snapshot(of view: UIView) -> UIImage? {
        guard view.bounds.width > 0, view.bounds.height > 0 else { return nil }
        return UIGraphicsImageRenderer(bounds: view.bounds).image { context in
            view.layer.render(in: context.cgContext)
        }
    }
}
