//
//  DetailCardsExample.swift
//  LumiKitExample
//
//  Detail Cards: LMKDetailPageViewController: cards from a model, rows updated in place.
//

import LumiKitUI
import UIKit

// MARK: - Detail Cards

final class DetailCardsDetailViewController: LMKDetailPageViewController {
    private var wateredToday = false
    private var rating = 3
    private var photoCount = 5
    private var tags = ["Bright indirect", "Humid", "Weekly"]
    private lazy var samplePhotos: [UIImage] = (0 ..< 8).map { index in
        let hue = CGFloat(index) / 8
        return UIImage.lmk_solidColor(UIColor(hue: hue, saturation: 0.45, brightness: 0.85, alpha: 1), size: CGSize(width: 200, height: 200))
    }

    init() {
        super.init(style: LMKScrollStackViewController.Style(widthMode: .readable, bottomAnchor: .superview))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Detail Cards"
        onEdit = { [weak self] in self?.enterEditMode() }
        onShare = { [weak self] in
            guard let self else { return }
            LMKToast.show(.info, "Share tapped", in: self)
        }
    }

    override func makeCards() -> [LMKDetailCard] {
        [
            LMKDetailCard(id: "intro", rows: [
                .text(.init(
                    id: "about",
                    content: .markdown(
                        "An **LMKDetailPageViewController** builds cards from a model and reconciles them by id. Tap Mark Watered to see rows update in place; tap the pencil for the edit flow."
                    )
                )),
            ]),
            LMKDetailCard(id: "header", header: .init(
                icon: .symbol("leaf.fill"),
                title: "Monstera deliciosa",
                subtitles: ["Swiss cheese plant", "Araceae"],
                trailing: [.button(systemName: "book", accessibilityLabel: "Wikipedia") { [weak self] in self?.toast("Wikipedia") }],
                isCopyable: true
            ), rows: [
                .chips(.init(id: "tags", items: tags.enumerated().map { index, tag in
                    .init(id: "tag-\(index)", text: tag, tint: index == 0 ? LMKColor.warning : nil) { [weak self] in self?.toast(tag) }
                })),
                .image(.init(id: "hero", image: samplePhotos[2], maxHeight: 160, accessibilityLabel: "Sample hero image")),
            ]),
            LMKDetailCard(id: "care", header: .init(icon: .symbol("drop.fill", tint: LMKColor.info), title: "Care"), rows: [
                .keyValue(.init(id: "schedule", key: "Watering", value: "Every 7 days", layout: .inline)),
                .keyValue(.init(id: "last", key: "Last watered", value: wateredToday ? "Today" : "6 days ago", layout: .inline, valueColor: wateredToday ? LMKColor.success : nil)),
                .progress(.init(id: "next", title: "Next watering", value: wateredToday ? 0 : 0.85, detail: wateredToday ? "In 7 days" : "Tomorrow")),
                .keyValue(.init(
                    id: "light",
                    key: "Light",
                    value: "Bright, indirect. Tolerates a few hours of morning sun but scorches in full afternoon light.",
                    description: "Measured at the east window"
                )),
                .keyValue(.init(id: "id", key: "Identifier", value: "MON-0042", isCopyable: true)),
                .navigation(.init(id: "journal", title: "Care journal", subtitle: "Waterings, fertilizer, pruning", systemName: "book", detail: "12") { [weak self] in self?.toast("Journal") }),
            ], actions: [
                .init(
                    id: "water",
                    title: wateredToday ? "Watered Today" : "Mark Watered",
                    role: .primary,
                    isEnabled: !wateredToday,
                    onLongPress: { [weak self] in self?.toast("Long press: log a past watering") },
                    onTap: { [weak self] in self?.markWatered() }
                ),
                .init(id: "fertilize", title: "Fertilize", role: .secondary) { [weak self] in self?.toast("Fertilize") },
                .init(id: "prune", title: "Prune", role: .secondary) { [weak self] in self?.toast("Prune") },
            ], actionsLayout: .leadingPrimary),
            LMKDetailCard(id: "photos", header: .init(
                icon: .symbol("photo.on.rectangle"),
                title: "Photos",
                trailing: [.textButton("Add") { [weak self] in self?.addPhoto() }]
            ), rows: [
                .photoStrip(.init(
                    id: "strip",
                    count: photoCount,
                    image: { [weak self] index in self?.samplePhotos[index % 8] },
                    caption: { "Day \($0 * 3 + 1)" },
                    isSelected: { $0 == 1 },
                    badgeSymbol: { $0 == 0 ? "star.fill" : nil },
                    onTap: { [weak self] index in self?.toast("Photo \(index + 1)") },
                    emptyState: .init(message: "No photos yet", icon: .system("photo"))
                )),
            ]),
            LMKDetailCard(id: "links", header: .init(title: "Links & rating"), rows: [
                .link(.init(
                    id: "guide",
                    title: "Care guide",
                    subtitle: "example.com",
                    url: URL(string: "https://example.com"),
                    icon: .symbol("link"),
                    onRemove: { [weak self] in self?.toast("Remove link") }
                )),
                .link(.init(id: "shop", title: "Where to buy", url: URL(string: "https://example.com/shop"), icon: .symbol("cart"))),
                .divider(id: "d1"),
                .rating(.init(id: "rating", title: "Your rating", value: rating) { [weak self] value in
                    self?.rating = value
                    self?.toast("Rated \(value)")
                }),
            ], style: LMKDetailCardView.Style(showsRowDividers: false, underlinesLinks: true)),
            LMKDetailCard(id: "hidden", header: .init(title: "Never shown"), isHidden: true),
        ]
    }

    private func markWatered() {
        wateredToday = true
        guard let care = cardView(id: "care") else { return }
        care.setValue("Today", color: LMKColor.success, forRowID: "last")
        care.update(rowID: "next") { row in
            row = .progress(.init(id: "next", title: "Next watering", value: 0, detail: "In 7 days"))
        }
        care.setAction("water", enabled: false)
        care.actionButtons["water"]?.title = "Watered Today"
        toast("Rows updated in place")
    }

    private func addPhoto() {
        photoCount = min(photoCount + 1, 8)
        reloadCards()
        toast("Photo strip reconfigured without losing its tiles")
    }

    private func enterEditMode() {
        cardView(id: "header")?.setHeaderLoading(true)
        beginEditing(onSave: { [weak self] in
            self?.cardView(id: "header")?.setHeaderLoading(false)
            self?.toast("Saved (⌘↩ also saves)")
        }, onCancel: { [weak self] in
            self?.cardView(id: "header")?.setHeaderLoading(false)
            self?.toast("Cancelled (Esc also cancels)")
        })
    }

    private func toast(_ message: String) {
        LMKToast.show(.info, message, in: self)
    }
}
