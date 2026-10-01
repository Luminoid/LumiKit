//
//  LMKDetailCard.swift
//  LumiKit
//
//  The rendering description of one detail card: a header, typed rows keyed
//  by id, and an action block. `LMKDetailCardView` renders it and updates rows
//  in place by id; `LMKDetailPageViewController` diffs whole cards by id.
//

import UIKit

/// One card of a detail page: header, rows, actions.
///
/// ```swift
/// LMKDetailCard(id: "care", header: .init(icon: .symbol("drop.fill"), title: "Care"), rows: [
///     .keyValue(.init(id: "water", key: "Watering", value: "Every 7 days")),
///     .progress(.init(id: "next", title: "Next watering", value: 0.6, detail: "3 days")),
///     .navigation(.init(id: "journal", title: "Care journal", systemName: "book", detail: "12") { showJournal() }),
/// ], actions: [
///     .init(id: "water", title: "Mark Watered", role: .primary) { markWatered() },
/// ])
/// ```
///
/// The model is a description only: pickers, forms, and data flows stay in the host. Every row
/// carries an `id` so `LMKDetailCardView.update(rowID:_:)` can change one row without rebuilding
/// the card.
public struct LMKDetailCard: Identifiable {
    // MARK: - Header

    /// A glyph in the header or a row.
    public enum Icon {
        /// An SF Symbol, tinted with `tint` (`nil` = the style's icon tint).
        case symbol(String, tint: UIColor? = nil)
        case image(UIImage, tint: UIColor? = nil)

        var image: UIImage? {
            switch self {
            case let .symbol(name, _): UIImage(systemName: name)
            case let .image(image, _): image
            }
        }

        var tint: UIColor? {
            switch self {
            case let .symbol(_, tint), let .image(_, tint): tint
            }
        }
    }

    /// A control at the trailing edge of the header.
    public enum TrailingItem {
        /// An icon button.
        case button(systemName: String, accessibilityLabel: String, onTap: () -> Void)
        /// A text button.
        case textButton(String, onTap: () -> Void)
        case badge(LMKBadgeView.Content)
        /// Read-only text (a count, a status).
        case text(String)
        case view(UIView)
    }

    public struct Header {
        public var icon: Icon?
        public var title: String
        /// `nil` = the style's header title text style.
        public var titleTextStyle: LMKTextStyle?
        /// Lines under the title.
        public var subtitles: [String]
        public var trailing: [TrailingItem]
        /// Shows an activity indicator after the trailing items.
        public var isLoading: Bool
        /// Long-press copies the title.
        public var isCopyable: Bool
        /// Makes the header a button.
        public var onTap: (() -> Void)?

        public init(
            icon: Icon? = nil,
            title: String,
            titleTextStyle: LMKTextStyle? = nil,
            subtitles: [String] = [],
            trailing: [TrailingItem] = [],
            isLoading: Bool = false,
            isCopyable: Bool = false,
            onTap: (() -> Void)? = nil
        ) {
            self.icon = icon
            self.title = title
            self.titleTextStyle = titleTextStyle
            self.subtitles = subtitles
            self.trailing = trailing
            self.isLoading = isLoading
            self.isCopyable = isCopyable
            self.onTap = onTap
        }
    }

    // MARK: - Rows

    /// How a key/value row lays out.
    public nonisolated enum KeyValueLayout: Sendable, Hashable, CaseIterable {
        /// Key leading, value trailing on the same line (the value wraps under itself).
        case inline
        /// Key above the value.
        case stacked
    }

    public struct KeyValue {
        public var id: String
        public var key: String
        public var value: String
        public var layout: KeyValueLayout
        /// `nil` = the style's value color (a status color otherwise).
        public var valueColor: UIColor?
        /// A caption under the row.
        public var description: String?
        /// Long-press copies `copyText ?? value`.
        public var isCopyable: Bool
        public var copyText: String?
        public var onTap: (() -> Void)?

        public init(
            id: String,
            key: String,
            value: String,
            layout: KeyValueLayout = .stacked,
            valueColor: UIColor? = nil,
            description: String? = nil,
            isCopyable: Bool = false,
            copyText: String? = nil,
            onTap: (() -> Void)? = nil
        ) {
            self.id = id
            self.key = key
            self.value = value
            self.layout = layout
            self.valueColor = valueColor
            self.description = description
            self.isCopyable = isCopyable
            self.copyText = copyText
            self.onTap = onTap
        }
    }

    public enum TextContent {
        case plain(String)
        /// Inline markdown (bold, italic, code) rendered with `LMKMarkdownRenderer`; the row is a
        /// label, so use a `.link` row for URLs.
        case markdown(String)
        case attributed(NSAttributedString)
    }

    public struct Text {
        public var id: String
        /// An optional heading above the text.
        public var title: String?
        public var content: TextContent
        public var textStyle: LMKTextStyle?
        public var color: UIColor?

        public init(id: String, title: String? = nil, content: TextContent, textStyle: LMKTextStyle? = nil, color: UIColor? = nil) {
            self.id = id
            self.title = title
            self.content = content
            self.textStyle = textStyle
            self.color = color
        }

        public init(id: String, title: String? = nil, text: String) {
            self.init(id: id, title: title, content: .plain(text))
        }
    }

    public struct Chip {
        public var id: String
        public var text: String
        public var icon: UIImage?
        public var tint: UIColor?
        public var onTap: (() -> Void)?

        public init(id: String, text: String, icon: UIImage? = nil, tint: UIColor? = nil, onTap: (() -> Void)? = nil) {
            self.id = id
            self.text = text
            self.icon = icon
            self.tint = tint
            self.onTap = onTap
        }
    }

    public struct Chips {
        public var id: String
        public var items: [Chip]

        public init(id: String, items: [Chip]) {
            self.id = id
            self.items = items
        }
    }

    public struct PhotoStrip {
        public var id: String
        public var count: Int
        /// Loads the image for a tile (off the main actor is fine); called lazily per tile.
        public var image: @MainActor (Int) async -> UIImage?
        /// A caption under a tile (a date).
        public var caption: ((Int) -> String?)?
        /// Whether a tile shows the selection checkmark.
        public var isSelected: ((Int) -> Bool)?
        /// An SF Symbol badge at a tile's top-trailing corner (a category glyph).
        public var badgeSymbol: ((Int) -> String?)?
        public var onTap: ((Int) -> Void)?
        /// Shown in place of the strip when `count == 0`.
        public var emptyState: LMKEmptyStateView.Content?

        public init(
            id: String,
            count: Int,
            image: @escaping @MainActor (Int) async -> UIImage?,
            caption: ((Int) -> String?)? = nil,
            isSelected: ((Int) -> Bool)? = nil,
            badgeSymbol: ((Int) -> String?)? = nil,
            onTap: ((Int) -> Void)? = nil,
            emptyState: LMKEmptyStateView.Content? = nil
        ) {
            self.id = id
            self.count = count
            self.image = image
            self.caption = caption
            self.isSelected = isSelected
            self.badgeSymbol = badgeSymbol
            self.onTap = onTap
            self.emptyState = emptyState
        }
    }

    public struct Progress {
        public var id: String
        public var title: String
        /// `0 ... 1`, clamped on every write; a NaN or infinite value (`done / total` with
        /// `total == 0`) becomes `0` instead of reaching Auto Layout.
        public var value: Float {
            didSet { value = Self.clamped(value) }
        }

        /// Trailing text ("3 days", "60%").
        public var detail: String?
        public var tint: UIColor?

        public init(id: String, title: String, value: Float, detail: String? = nil, tint: UIColor? = nil) {
            self.id = id
            self.title = title
            self.value = Self.clamped(value)
            self.detail = detail
            self.tint = tint
        }

        /// `value` in `0 ... 1`; `0` when it is not a finite number.
        static func clamped(_ value: Float) -> Float {
            value.isFinite ? min(max(value, 0), 1) : 0
        }
    }

    public struct Navigation {
        public var id: String
        /// The row content; `trailing` is forced to `.disclosure`.
        public var configuration: LMKListRowConfiguration
        public var onTap: () -> Void

        public init(id: String, configuration: LMKListRowConfiguration, onTap: @escaping () -> Void) {
            self.id = id
            self.configuration = configuration
            self.onTap = onTap
        }

        public init(id: String, title: String, subtitle: String? = nil, systemName: String? = nil, tint: UIColor? = nil, detail: String? = nil, onTap: @escaping () -> Void) {
            self.init(
                id: id,
                configuration: LMKListRowConfiguration(title: title, subtitle: subtitle, detail: detail, leading: systemName.map { .symbol($0, tint: tint) } ?? .none, trailing: .disclosure),
                onTap: onTap
            )
        }
    }

    public struct Link {
        public var id: String
        public var title: String
        public var subtitle: String?
        public var url: URL?
        public var icon: Icon?
        /// Replaces opening `url` in the system browser.
        public var onOpen: (() -> Void)?
        /// Shows a trailing remove button.
        public var onRemove: (() -> Void)?

        public init(id: String, title: String, subtitle: String? = nil, url: URL? = nil, icon: Icon? = nil, onOpen: (() -> Void)? = nil, onRemove: (() -> Void)? = nil) {
            self.id = id
            self.title = title
            self.subtitle = subtitle
            self.url = url
            self.icon = icon
            self.onOpen = onOpen
            self.onRemove = onRemove
        }
    }

    public struct Rating {
        public var id: String
        public var title: String
        public var value: Int
        public var maximum: Int
        /// Called on user changes; `nil` renders read-only.
        public var onValueChange: ((Int) -> Void)?

        public init(id: String, title: String, value: Int, maximum: Int = 5, onValueChange: ((Int) -> Void)? = nil) {
            self.id = id
            self.title = title
            self.value = value
            self.maximum = maximum
            self.onValueChange = onValueChange
        }
    }

    public struct Image {
        public var id: String
        public var image: UIImage?
        /// Loads the image when `image` is `nil`.
        public var load: (@MainActor () async -> UIImage?)?
        /// `nil` = the style's maximum.
        public var maxHeight: CGFloat?
        public var contentMode: UIView.ContentMode
        public var onTap: (() -> Void)?
        public var accessibilityLabel: String?

        public init(
            id: String,
            image: UIImage? = nil,
            load: (@MainActor () async -> UIImage?)? = nil,
            maxHeight: CGFloat? = nil,
            contentMode: UIView.ContentMode = .scaleAspectFit,
            onTap: (() -> Void)? = nil,
            accessibilityLabel: String? = nil
        ) {
            self.id = id
            self.image = image
            self.load = load
            self.maxHeight = maxHeight
            self.contentMode = contentMode
            self.onTap = onTap
            self.accessibilityLabel = accessibilityLabel
        }
    }

    public enum Row {
        case keyValue(KeyValue)
        case text(Text)
        case chips(Chips)
        case photoStrip(PhotoStrip)
        case progress(Progress)
        /// A tappable row with a chevron, rendered as an `LMKListRowConfiguration`.
        case navigation(Navigation)
        case link(Link)
        case rating(Rating)
        /// A hero image bound to its aspect ratio and a maximum height.
        case image(Image)
        case divider(id: String)
        /// A host-built view (an embedded collection, a map preview).
        case custom(id: String, UIView)

        public var id: String {
            switch self {
            case let .keyValue(row): row.id
            case let .text(row): row.id
            case let .chips(row): row.id
            case let .photoStrip(row): row.id
            case let .progress(row): row.id
            case let .navigation(row): row.id
            case let .link(row): row.id
            case let .rating(row): row.id
            case let .image(row): row.id
            case let .divider(id): id
            case let .custom(id, _): id
            }
        }

        /// Stable across updates of the same row kind.
        var kind: Int {
            switch self {
            case .keyValue: 0
            case .text: 1
            case .chips: 2
            case .photoStrip: 3
            case .progress: 4
            case .navigation: 5
            case .link: 6
            case .rating: 7
            case .image: 8
            case .divider: 9
            case .custom: 10
            }
        }

        public static func divider() -> Self {
            .divider(id: UUID().uuidString)
        }
    }

    // MARK: - Actions

    public struct Action {
        public var id: String
        public var title: String
        public var role: LMKButton.Role
        public var image: UIImage?
        public var isEnabled: Bool
        /// Replaces the style's button style for this role.
        public var style: LMKButton.Style?
        public var onTap: () -> Void
        public var onLongPress: (() -> Void)?

        public init(
            id: String,
            title: String,
            role: LMKButton.Role = .primary,
            image: UIImage? = nil,
            isEnabled: Bool = true,
            style: LMKButton.Style? = nil,
            onLongPress: (() -> Void)? = nil,
            onTap: @escaping () -> Void
        ) {
            self.id = id
            self.title = title
            self.role = role
            self.image = image
            self.isEnabled = isEnabled
            self.style = style
            self.onLongPress = onLongPress
            self.onTap = onTap
        }
    }

    /// How action buttons are arranged.
    public nonisolated enum ActionsLayout: Sendable, Hashable, CaseIterable {
        /// Every button on its own full-width row.
        case stacked
        /// Two per row; a lone last button spans the row.
        case pairs
        /// The first button full width, the rest in pairs.
        case leadingPrimary
        /// All buttons on one row, equal widths.
        case inline
    }

    // MARK: - Card

    public var id: String
    public var header: Header?
    public var rows: [Row]
    public var actions: [Action]
    public var actionsLayout: ActionsLayout
    /// Layered over the page's / theme's style for this card only.
    public var style: LMKDetailCardView.Style?
    /// A hidden card takes no space (and no stack spacing).
    public var isHidden: Bool

    public init(
        id: String,
        header: Header? = nil,
        rows: [Row] = [],
        actions: [Action] = [],
        actionsLayout: ActionsLayout = .stacked,
        style: LMKDetailCardView.Style? = nil,
        isHidden: Bool = false
    ) {
        self.id = id
        self.header = header
        self.rows = rows
        self.actions = actions
        self.actionsLayout = actionsLayout
        self.style = style
        self.isHidden = isHidden
    }

    /// A card with a plain title.
    public init(id: String, title: String, rows: [Row] = [], actions: [Action] = [], actionsLayout: ActionsLayout = .stacked) {
        self.init(id: id, header: Header(title: title), rows: rows, actions: actions, actionsLayout: actionsLayout)
    }

    /// The row with `id`, if any.
    public func row(id: String) -> Row? {
        rows.first { $0.id == id }
    }
}
