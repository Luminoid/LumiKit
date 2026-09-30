//
//  LMKNarrowFirstLayoutTests.swift
//  LumiKit
//
//  A view can be laid out at a collapsed width before its container has its
//  real size (a scroll view's readable guide before the window arrives, a stack
//  filled in `viewDidLoad`). A wrapping label that takes its width from its own
//  content keeps the narrow width of that first pass; every component here must
//  reach the same height as an instance that only ever saw the real width.
//

import Testing
import UIKit
@testable import LumiKitUI

// MARK: - Narrow-first layout

@MainActor
struct LMKNarrowFirstLayoutTests {
    private static let longText = "We'll never share your email with anyone outside your team."

    /// Pins `view` to the top of a container and returns its height at `width`,
    /// optionally after a first pass at a collapsed width.
    private static func height(of view: UIView, width: CGFloat, narrowFirst: Bool) -> CGFloat {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: narrowFirst ? 24 : width, height: 2000))
        container.addSubview(view)
        view.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }
        container.layoutIfNeeded()
        if narrowFirst {
            container.frame.size.width = width
            container.setNeedsLayout()
            container.layoutIfNeeded()
        }
        return view.bounds.height
    }

    private static func expectStable(_ name: String, width: CGFloat = 320, _ make: () -> UIView) {
        let fresh = height(of: make(), width: width, narrowFirst: false)
        let recovered = height(of: make(), width: width, narrowFirst: true)
        #expect(fresh > 0, "\(name) has no height")
        #expect(abs(fresh - recovered) < 0.5, "\(name): \(recovered)pt after a narrow first pass, \(fresh)pt fresh")
    }

    @Test
    func `A text field helper recovers from a narrow first pass`() {
        Self.expectStable("LMKTextField") {
            let field = LMKTextField()
            field.placeholder = "Email"
            field.helperText = Self.longText
            return field
        }
    }

    @Test
    func `A text field helper beside a counter recovers from a narrow first pass`() {
        Self.expectStable("LMKTextField + counter") {
            let field = LMKTextField()
            field.helperText = Self.longText
            field.maxCharacterCount = 40
            field.showsCharacterCount = true
            return field
        }
    }

    @Test
    func `A text field helper fills the row on one line when it fits`() {
        let field = LMKTextField()
        field.helperText = "Short helper."
        _ = Self.height(of: field, width: 320, narrowFirst: true)
        let label = field.helperLabel
        #expect(label.bounds.width > 200)
        #expect(label.bounds.height < label.font.lineHeight * 1.6)
    }

    @Test
    func `A text view helper recovers from a narrow first pass`() {
        Self.expectStable("LMKTextView") {
            let view = LMKTextView()
            view.helperText = Self.longText
            return view
        }
    }

    @Test
    func `A banner recovers from a narrow first pass`() {
        Self.expectStable("LMKBannerView") {
            LMKBannerView(status: .info, message: Self.longText + " " + Self.longText)
        }
    }

    @Test
    func `A status label recovers from a narrow first pass`() {
        Self.expectStable("LMKStatusLabel") {
            let label = LMKStatusLabel()
            label.show(Self.longText + " " + Self.longText, status: .warning)
            return label
        }
    }

    @Test
    func `An empty state recovers from a narrow first pass`() {
        for layout in LMKEmptyStateView.Layout.allCases {
            Self.expectStable("LMKEmptyStateView \(layout)") {
                let view = LMKEmptyStateView(style: LMKEmptyStateView.Style(layout: layout))
                view.configure(LMKEmptyStateView.Content(title: "Nothing here yet", message: Self.longText, icon: .system("tray")))
                return view
            }
        }
    }

    @Test
    func `A list row recovers from a narrow first pass`() {
        Self.expectStable("LMKListRowContentView") {
            LMKListRowContentView(configuration: LMKListRowConfiguration(
                title: "Destinations with a long title that wraps",
                subtitle: Self.longText,
                detail: "3",
                leading: .symbol("map", tint: nil),
                trailing: .disclosure,
                style: LMKListRowConfiguration.Style(titleLines: 0, subtitleLines: 0)
            ))
        }
    }

    @Test
    func `An action sheet row recovers from a narrow first pass`() {
        Self.expectStable("LMKActionSheetRowView") {
            let row = LMKActionSheetRowView()
            row.configure(LMKActionSheetRowView.Content(title: "Share a copy", subtitle: Self.longText, icon: UIImage(systemName: "square.and.arrow.up")))
            return row
        }
    }

    @Test
    func `A detail card recovers from a narrow first pass`() {
        Self.expectStable("LMKDetailCardView") {
            LMKDetailCardView(card: LMKDetailCard(
                id: "care",
                header: LMKDetailCard.Header(title: "Care", subtitles: [Self.longText]),
                rows: [
                    .keyValue(LMKDetailCard.KeyValue(id: "light", key: "Light", value: Self.longText, layout: .stacked, description: Self.longText)),
                    .keyValue(LMKDetailCard.KeyValue(id: "water", key: "Watering", value: "Every 7 days")),
                    .text(LMKDetailCard.Text(id: "notes", title: "Notes", text: Self.longText + " " + Self.longText)),
                ]
            ))
        }
    }
}
