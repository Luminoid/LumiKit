//
//  ExampleAccessibilityAudit.swift
//  LumiKitExample
//
//  A view-hierarchy audit for the sweep: truncated labels, content clipped by
//  the window, overlapping siblings, small touch targets, unlabeled controls,
//  low text contrast, and fixed fonts. Printed one line per finding so a script
//  can collect them per page and configuration.
//

import LumiKitUI
import UIKit

enum ExampleAccessibilityAudit {
    enum Severity: String { case error, warning, info }

    struct Finding: CustomStringConvertible {
        var severity: Severity
        var check: String
        var path: String
        var detail: String

        var description: String { "\(severity.rawValue)|\(check)|\(path)|\(detail)" }
    }

    /// The minimum touch target, from the theme so a custom layout token is honored.
    private static var minimumTarget: CGFloat { LMKTheme.current.layout.minimumTouchTarget }

    /// Audits `root` (a page's view) inside `window`.
    @MainActor
    static func run(on root: UIView, in window: UIWindow) -> [Finding] {
        var findings: [Finding] = []
        walk(root, path: [], window: window, insideHorizontalScroller: false, insideCell: false, findings: &findings)
        return findings
    }

    // MARK: - Walk

    @MainActor
    private static func walk(_ view: UIView, path: [String], window: UIWindow, insideHorizontalScroller: Bool, insideCell: Bool, findings: inout [Finding]) {
        guard !view.isHidden, view.alpha > 0.01, view.window === window else { return }
        let path = path + [name(of: view)]
        let pathText = path.suffix(4).joined(separator: " > ")
        let frameInWindow = view.convert(view.bounds, to: window)

        if let label = view as? UILabel, let text = label.text, !text.isEmpty, label.bounds.width > 0 {
            checkTruncation(label, path: pathText, findings: &findings)
            checkContrast(label, path: pathText, findings: &findings)
            // A button's or text field's own label is re-fonted by its owner on a category change.
            if !label.adjustsFontForContentSizeCategory, !insideOwnerThatScales(label) {
                findings.append(Finding(severity: .info, check: "fixedFont", path: pathText, detail: "\(Int(label.font.pointSize))pt not scaling"))
            }
        }

        if !insideHorizontalScroller, isContent(view), view.bounds.width > 0 {
            let overflow = max(window.bounds.minX - frameInWindow.minX, frameInWindow.maxX - window.bounds.maxX)
            if overflow > 1 {
                findings.append(Finding(severity: .error, check: "clippedHorizontally", path: pathText, detail: "\(Int(overflow))pt past the window edge"))
            }
        }

        // An element inside a control (a segment label, a slider track) is reached through the
        // control's own hit area; the control is what the sweep measures.
        let ownedByControl = insideCell || hasControlAncestor(view)
        let isStatic = view.accessibilityTraits.contains(.staticText) || view.accessibilityTraits.contains(.notEnabled)
        if let control = view as? UIControl, !control.isEnabled || isStatic {
            // A disabled control or a display-only one (a chip without a handler) is not a target.
        } else if let control = view as? UIControl, control.isUserInteractionEnabled {
            checkTarget(control, path: pathText, insideCell: ownedByControl, findings: &findings)
            checkLabel(control, path: pathText, findings: &findings)
        } else if view.isAccessibilityElement, !isStatic, view.accessibilityTraits.contains(.button) || view.accessibilityTraits.contains(.adjustable) {
            checkTarget(view, path: pathText, insideCell: ownedByControl, findings: &findings)
            if (view.accessibilityLabel ?? "").isEmpty {
                findings.append(Finding(severity: .warning, check: "unlabeled", path: pathText, detail: "accessibility element without a label"))
            }
        }

        checkOverlaps(in: view, path: pathText, findings: &findings)

        let scrollsHorizontally = insideHorizontalScroller || ((view as? UIScrollView).map { $0.contentSize.width > $0.bounds.width + 1 } ?? false)
        let cell = insideCell || view is UITableViewCell || view is UICollectionViewCell
        for subview in view.subviews {
            walk(subview, path: path, window: window, insideHorizontalScroller: scrollsHorizontally, insideCell: cell, findings: &findings)
        }
    }

    private static func isContent(_ view: UIView) -> Bool {
        view is UILabel || view is UIControl || view is UIImageView
    }

    @MainActor
    private static func hasControlAncestor(_ view: UIView) -> Bool {
        var current = view.superview
        while let ancestor = current {
            if ancestor is UIControl { return true }
            current = ancestor.superview
        }
        return false
    }

    @MainActor
    private static func insideOwnerThatScales(_ label: UILabel) -> Bool {
        var current = label.superview
        while let ancestor = current {
            if ancestor is UIButton || ancestor is UITextField { return true }
            current = ancestor.superview
        }
        return false
    }

    @MainActor
    private static func name(of view: UIView) -> String {
        let type = String(describing: Swift.type(of: view))
        if let label = view as? UILabel, let text = label.text, !text.isEmpty {
            return "\(type)(\"\(text.prefix(24))\")"
        }
        if let button = view as? UIButton, let title = button.configuration?.title ?? button.currentTitle, !title.isEmpty {
            return "\(type)(\"\(title.prefix(24))\")"
        }
        if let identifier = view.accessibilityIdentifier, !identifier.isEmpty {
            return "\(type)(#\(identifier))"
        }
        return type
    }

    // MARK: - Checks

    @MainActor
    private static func checkTruncation(_ label: UILabel, path: String, findings: inout [Finding]) {
        let width = label.bounds.width
        if label.numberOfLines == 1 {
            let needed = label.intrinsicContentSize.width
            if needed > width + 1, label.adjustsFontSizeToFitWidth == false, label.lineBreakMode != .byWordWrapping {
                findings.append(Finding(severity: .error, check: "truncated", path: path, detail: "needs \(Int(needed))pt, has \(Int(width))pt"))
            }
        } else {
            let needed = label.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude)).height
            if needed > label.bounds.height + 1 {
                findings.append(Finding(severity: .error, check: "truncated", path: path, detail: "needs \(Int(needed))pt tall, has \(Int(label.bounds.height))pt"))
            }
        }
    }

    @MainActor
    private static func checkTarget(_ view: UIView, path: String, insideCell: Bool, findings: inout [Finding]) {
        let minimum = minimumTarget
        let size = view.bounds.size
        guard size.width > 0, size.height > 0, size.width < minimum - 0.5 || size.height < minimum - 0.5 else { return }
        // The control may expand its own hit area; probe the corners of a minimum box around its center.
        let center = CGPoint(x: view.bounds.midX, y: view.bounds.midY)
        let half = minimum / 2 - 0.5
        let corners = [
            CGPoint(x: center.x - half, y: center.y - half), CGPoint(x: center.x + half, y: center.y - half),
            CGPoint(x: center.x - half, y: center.y + half), CGPoint(x: center.x + half, y: center.y + half),
        ]
        let expands = corners.allSatisfy { view.point(inside: $0, with: nil) }
        guard !expands else { return }
        let severity: Severity = insideCell ? .info : .warning
        findings.append(Finding(severity: severity, check: "smallTarget", path: path, detail: "\(Int(size.width))×\(Int(size.height))pt\(insideCell ? " (row is the target)" : "")"))
    }

    @MainActor
    private static func checkLabel(_ control: UIControl, path: String, findings: inout [Finding]) {
        guard control.isAccessibilityElement || control is UIButton else { return }
        if let label = control.accessibilityLabel, !label.isEmpty { return }
        if let button = control as? UIButton {
            let title = button.configuration?.title ?? button.currentTitle ?? button.configuration?.attributedTitle?.characters.map(String.init).joined()
            if let title, !title.isEmpty { return }
            if button.configuration?.image != nil || button.currentImage != nil {
                findings.append(Finding(severity: .warning, check: "unlabeled", path: path, detail: "image-only button without an accessibility label"))
            }
            return
        }
        if control is UITextField || control is UISwitch || control is UISlider || control is UISegmentedControl { return }
        findings.append(Finding(severity: .warning, check: "unlabeled", path: path, detail: "control without an accessibility label"))
    }

    @MainActor
    private static func checkOverlaps(in view: UIView, path: String, findings: inout [Finding]) {
        let children = view.subviews.filter { !$0.isHidden && $0.alpha > 0.01 && isContent($0) && !$0.bounds.isEmpty }
        guard children.count > 1 else { return }
        for (index, first) in children.enumerated() {
            for second in children[(index + 1)...] {
                let intersection = first.frame.intersection(second.frame)
                guard !intersection.isNull, intersection.width > 2, intersection.height > 2 else { continue }
                // A label over an image (a caption on a photo) is a design, not a defect.
                if first is UIImageView || second is UIImageView { continue }
                findings.append(Finding(severity: .warning, check: "overlap", path: path, detail: "\(name(of: first)) ∩ \(name(of: second)) \(Int(intersection.width))×\(Int(intersection.height))pt"))
            }
        }
    }

    @MainActor
    private static func checkContrast(_ label: UILabel, path: String, findings: inout [Finding]) {
        guard let background = effectiveBackground(behind: label) else { return }
        let traits = label.traitCollection
        let text = label.textColor.resolvedColor(with: traits)
        let fill = background.resolvedColor(with: traits)
        let ratio = contrastRatio(text, fill)
        let pointSize = label.font.pointSize
        let isBold = label.font.fontDescriptor.symbolicTraits.contains(.traitBold)
        let isLarge = pointSize >= 24 || (isBold && pointSize >= 18.66)
        let required: Double = isLarge ? 3 : 4.5
        if ratio < required {
            let detail = String(format: "%.2f:1 (needs %.1f:1) #%@ on #%@", ratio, required, text.lmk_hexString, fill.lmk_hexString)
            findings.append(Finding(severity: .warning, check: "contrast", path: path, detail: detail))
        }
    }

    /// The first opaque background behind `label`; `nil` behind a blur, an image, or a clear stack.
    ///
    /// A view's fill can live on a full-size child (a button configuration's background view,
    /// a surface's gradient or blur), so each ancestor's covering children count as its background.
    @MainActor
    private static func effectiveBackground(behind label: UILabel) -> UIColor? {
        var view: UIView? = label
        var previous: UIView = label
        while let current = view {
            if current is UIVisualEffectView || current is UIImageView { return nil }
            if let color = opaqueColor(of: current) { return color }
            for child in current.subviews where child !== previous && !child.isHidden && child.alpha > 0.01 && covers(child, current) {
                if child is UIVisualEffectView || child is UIImageView || child.layer is CAGradientLayer { return nil }
                if let color = opaqueColor(of: child) { return color }
                if let nested = child.subviews.first(where: { covers($0, child) }), let color = opaqueColor(of: nested) { return color }
            }
            previous = current
            view = current.superview
        }
        return nil
    }

    @MainActor
    private static func opaqueColor(of view: UIView) -> UIColor? {
        guard let color = view.backgroundColor, color.resolvedColor(with: view.traitCollection).cgColor.alpha >= 0.99 else { return nil }
        return color
    }

    @MainActor
    private static func covers(_ child: UIView, _ parent: UIView) -> Bool {
        child.frame.insetBy(dx: -1, dy: -1).contains(parent.bounds)
    }

    // MARK: - WCAG contrast

    static func contrastRatio(_ a: UIColor, _ b: UIColor) -> Double {
        let la = relativeLuminance(a)
        let lb = relativeLuminance(b)
        let lighter = max(la, lb)
        let darker = min(la, lb)
        return (lighter + 0.05) / (darker + 0.05)
    }

    static func relativeLuminance(_ color: UIColor) -> Double {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        func linear(_ channel: CGFloat) -> Double {
            let value = Double(channel)
            return value <= 0.03928 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linear(red) + 0.7152 * linear(green) + 0.0722 * linear(blue)
    }
}
