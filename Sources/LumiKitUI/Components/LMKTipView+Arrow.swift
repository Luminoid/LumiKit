//
//  LMKTipView+Arrow.swift
//  LumiKit
//
//  The arrow of a pointed tip: a rounded triangle outside the bubble's edge,
//  centered on the source and clamped inside the bubble's corners. A solid
//  bubble and its arrow are one outline, so a border and a shadow wrap both.
//

import UIKit

extension LMKTipView {
    /// The arrow's geometry in the bubble's coordinates.
    struct Arrow: Equatable {
        var pointsUp: Bool
        var centerX: CGFloat
        var width: CGFloat
        var height: CGFloat
        var tipRadius: CGFloat
    }

    /// Draws the arrow for `direction` pointing at `sourceFrame` (in this view's coordinates).
    func drawArrow(direction: ArrowDirection, sourceFrame: CGRect) {
        guard direction != .automatic else { return }
        let sourceInBubble = convert(sourceFrame, to: bubbleView)
        let bubbleBounds = bubbleView.bounds
        let arrowWidth = resolved.arrowWidth ?? Self.defaultArrowWidth
        let corners = resolvedSurface.corners ?? .none
        let cornerRadius = min(corners.resolvedRadius(for: bubbleBounds), bubbleBounds.width / 2, bubbleBounds.height / 2)

        let minX = bubbleBounds.minX + cornerRadius + arrowWidth / 2
        let maxX = bubbleBounds.maxX - cornerRadius - arrowWidth / 2
        let arrow = Arrow(
            pointsUp: direction == .up,
            centerX: min(max(sourceInBubble.midX, minX), max(minX, maxX)),
            width: arrowWidth,
            height: resolved.arrowHeight ?? Self.defaultArrowHeight,
            tipRadius: resolved.arrowTipRadius ?? Self.defaultArrowTipRadius
        )

        if drawsOutline {
            // A stroke straddles its path: inset by half the line so the border stays inside the bounds.
            let inset = outlineLayer.lineWidth / 2
            let path = Self.outlinePath(
                in: bubbleBounds.insetBy(dx: inset, dy: inset),
                cornerRadius: max(0, cornerRadius - inset),
                maskedCorners: corners.maskedCorners,
                arrow: arrow
            )
            outlineLayer.frame = bubbleBounds
            outlineLayer.path = path.cgPath
            outlineLayer.shadowPath = path.cgPath
            outlineLayer.isHidden = false
            arrowLayer.isHidden = true
            return
        }

        let path = UIBezierPath()
        let baseY = arrow.pointsUp ? bubbleBounds.minY : bubbleBounds.maxY
        path.move(to: CGPoint(x: arrow.centerX - arrow.width / 2, y: baseY))
        Self.addArrow(arrow, to: path, baseY: baseY, leftToRight: true)
        path.close()
        arrowLayer.path = path.cgPath
        arrowLayer.shadowColor = bubbleView.layer.shadowColor
        arrowLayer.shadowOffset = bubbleView.layer.shadowOffset
        arrowLayer.shadowRadius = bubbleView.layer.shadowRadius
        arrowLayer.shadowOpacity = bubbleView.layer.shadowOpacity
        arrowLayer.isHidden = false
        outlineLayer.isHidden = true
    }

    /// The two flanks and the rounded tip, from one end of the base to the other. The path's
    /// current point is the base's starting end.
    static func addArrow(_ arrow: Arrow, to path: UIBezierPath, baseY: CGFloat, leftToRight: Bool) {
        let tipY = arrow.pointsUp ? baseY - arrow.height : baseY + arrow.height
        let shoulderY = arrow.pointsUp ? tipY + arrow.tipRadius : tipY - arrow.tipRadius
        let sign: CGFloat = leftToRight ? 1 : -1
        path.addLine(to: CGPoint(x: arrow.centerX - sign * arrow.tipRadius, y: shoulderY))
        path.addQuadCurve(to: CGPoint(x: arrow.centerX + sign * arrow.tipRadius, y: shoulderY), controlPoint: CGPoint(x: arrow.centerX, y: tipY))
        path.addLine(to: CGPoint(x: arrow.centerX + sign * arrow.width / 2, y: baseY))
    }

    /// The bubble's rounded rectangle with the arrow cut into its top or bottom edge, clockwise.
    static func outlinePath(in rect: CGRect, cornerRadius: CGFloat, maskedCorners: CACornerMask, arrow: Arrow) -> UIBezierPath {
        func radius(_ corner: CACornerMask) -> CGFloat {
            maskedCorners.contains(corner) ? cornerRadius : 0
        }
        let topLeft = radius(.layerMinXMinYCorner)
        let topRight = radius(.layerMaxXMinYCorner)
        let bottomRight = radius(.layerMaxXMaxYCorner)
        let bottomLeft = radius(.layerMinXMaxYCorner)

        let path = UIBezierPath()
        path.move(to: CGPoint(x: rect.minX + topLeft, y: rect.minY))
        if arrow.pointsUp {
            path.addLine(to: CGPoint(x: arrow.centerX - arrow.width / 2, y: rect.minY))
            addArrow(arrow, to: path, baseY: rect.minY, leftToRight: true)
        }
        path.addLine(to: CGPoint(x: rect.maxX - topRight, y: rect.minY))
        if topRight > 0 {
            path.addArc(withCenter: CGPoint(x: rect.maxX - topRight, y: rect.minY + topRight), radius: topRight, startAngle: -.pi / 2, endAngle: 0, clockwise: true)
        }
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - bottomRight))
        if bottomRight > 0 {
            path.addArc(withCenter: CGPoint(x: rect.maxX - bottomRight, y: rect.maxY - bottomRight), radius: bottomRight, startAngle: 0, endAngle: .pi / 2, clockwise: true)
        }
        if !arrow.pointsUp {
            path.addLine(to: CGPoint(x: arrow.centerX + arrow.width / 2, y: rect.maxY))
            addArrow(arrow, to: path, baseY: rect.maxY, leftToRight: false)
        }
        path.addLine(to: CGPoint(x: rect.minX + bottomLeft, y: rect.maxY))
        if bottomLeft > 0 {
            path.addArc(withCenter: CGPoint(x: rect.minX + bottomLeft, y: rect.maxY - bottomLeft), radius: bottomLeft, startAngle: .pi / 2, endAngle: .pi, clockwise: true)
        }
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + topLeft))
        if topLeft > 0 {
            path.addArc(withCenter: CGPoint(x: rect.minX + topLeft, y: rect.minY + topLeft), radius: topLeft, startAngle: .pi, endAngle: .pi * 1.5, clockwise: true)
        }
        path.close()
        return path
    }
}
