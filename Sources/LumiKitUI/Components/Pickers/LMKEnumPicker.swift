//
//  LMKEnumPicker.swift
//  LumiKit
//
//  The enum picker namespace: the selectable protocol, Style, Strings, and
//  the single- and multi-select presenters. The sheet itself lives in
//  LMKEnumPickerViewController.
//

import UIKit

/// A value that can be listed in an `LMKEnumPicker`.
public nonisolated protocol LMKEnumSelectable {
    var displayName: String { get }
    /// An asset name or SF Symbol shown before the name; `nil` (the default) shows none.
    var iconName: String? { get }
}

/// `nonisolated` like the protocol: under the module's MainActor default the extension's
/// members would otherwise be main-actor-isolated, and a nonisolated conformer relying on
/// the default could not satisfy the requirement.
public nonisolated extension LMKEnumSelectable {
    var iconName: String? { nil }
}

/// Bottom sheet for picking one value, or several, from a list of `LMKEnumSelectable` values.
///
/// ```swift
/// LMKEnumPicker.present(from: self, title: "Sort By", options: SortOption.allCases, selection: sort) { sort = $0 }
/// LMKEnumPicker.present(from: self, title: "Filters", options: Filter.allCases, selection: filters) { filters = $0 }
/// ```
///
/// A `T?` selection is single-select (a tap commits and dismisses); a `Set<T>` is
/// multi-select (taps toggle, Done commits, Cancel discards). `onCancel` runs when the
/// sheet goes away without committing (Cancel, dimming tap, drag, key command).
public enum LMKEnumPicker {
    // MARK: - Style

    public nonisolated struct Style: Sendable, Equatable, LMKThemeExtension {
        /// The sheet chrome.
        public var sheet: LMKBottomSheetViewController.Style
        public var row: LMKActionSheet.RowStyle
        /// `nil` = `h3`.
        public var titleTextStyle: LMKTextStyle?
        /// `nil` = `textPrimary`.
        public var titleColor: UIColor?
        /// Layered on the default Done look (filled primary, 50pt).
        public var doneButton: LMKButton.Style
        public var searchBar: LMKSearchBar.Style
        /// Gap between rows; `nil` = `xs`.
        public var rowSpacing: CGFloat?

        public init(
            sheet: LMKBottomSheetViewController.Style = LMKBottomSheetViewController.Style(),
            row: LMKActionSheet.RowStyle = LMKActionSheet.RowStyle(),
            titleTextStyle: LMKTextStyle? = nil,
            titleColor: UIColor? = nil,
            doneButton: LMKButton.Style = LMKButton.Style(),
            searchBar: LMKSearchBar.Style = LMKSearchBar.Style(),
            rowSpacing: CGFloat? = nil
        ) {
            self.sheet = sheet
            self.row = row
            self.titleTextStyle = titleTextStyle
            self.titleColor = titleColor
            self.doneButton = doneButton
            self.searchBar = searchBar
            self.rowSpacing = rowSpacing
        }

        public static let defaultValue = Self()

        /// `other`'s non-nil fields over this style's.
        public func merging(_ other: Self) -> Self {
            Self(
                sheet: sheet.merging(other.sheet),
                row: row.merging(other.row),
                titleTextStyle: other.titleTextStyle ?? titleTextStyle,
                titleColor: other.titleColor ?? titleColor,
                doneButton: doneButton.merging(other.doneButton),
                searchBar: searchBar.merging(other.searchBar),
                rowSpacing: other.rowSpacing ?? rowSpacing
            )
        }
    }

    // MARK: - Strings

    public nonisolated struct Strings: Sendable, Equatable {
        /// Title of the multi-select commit button.
        public var done: String
        /// Placeholder of the search field.
        public var searchPlaceholder: String

        public init(
            done: String = LMKLocalized("enumPicker.done"),
            searchPlaceholder: String = LMKLocalized("enumPicker.search.placeholder")
        ) {
            self.done = done
            self.searchPlaceholder = searchPlaceholder
        }
    }

    /// Process-wide defaults; set at app launch to override.
    public nonisolated(unsafe) static var strings = Strings()

    // MARK: - Presentation

    /// Presents a single-select picker: tapping a row commits it and dismisses.
    @discardableResult
    public static func present<T: Hashable & LMKEnumSelectable>(
        from host: UIViewController,
        title: String,
        options: [T],
        selection: T?,
        disabledOptions: Set<T> = [],
        showsIcons: Bool = true,
        showsSearch: Bool = false,
        style: Style = Style(),
        strings: Strings = Self.strings,
        onSelect: @escaping (T) -> Void,
        onCancel: (() -> Void)? = nil
    ) -> LMKEnumPickerViewController {
        let sheet = LMKEnumPickerViewController(
            title: title,
            items: items(for: options, disabled: disabledOptions, showsIcons: showsIcons),
            selectedIndices: Set(selection.flatMap { options.firstIndex(of: $0) }.map { [$0] } ?? []),
            isMultiSelect: false,
            showsSearch: showsSearch,
            doneTitle: nil,
            style: style,
            strings: strings,
            onCommit: { indices in
                if let index = indices.first, let option = options[lmk_safe: index] {
                    onSelect(option)
                }
            },
            onCancel: onCancel
        )
        sheet.present(from: host)
        return sheet
    }

    /// Presents a multi-select picker: taps toggle rows, Done commits, Cancel discards.
    @discardableResult
    public static func present<T: Hashable & LMKEnumSelectable>(
        from host: UIViewController,
        title: String,
        options: [T],
        selection: Set<T>,
        disabledOptions: Set<T> = [],
        showsIcons: Bool = true,
        showsSearch: Bool = false,
        doneTitle: String? = nil,
        style: Style = Style(),
        strings: Strings = Self.strings,
        onSelect: @escaping (Set<T>) -> Void,
        onCancel: (() -> Void)? = nil
    ) -> LMKEnumPickerViewController {
        let sheet = LMKEnumPickerViewController(
            title: title,
            items: items(for: options, disabled: disabledOptions, showsIcons: showsIcons),
            selectedIndices: Set(selection.compactMap { options.firstIndex(of: $0) }),
            isMultiSelect: true,
            showsSearch: showsSearch,
            doneTitle: doneTitle,
            style: style,
            strings: strings,
            onCommit: { indices in
                onSelect(Set(indices.compactMap { options[lmk_safe: $0] }))
            },
            onCancel: onCancel
        )
        sheet.present(from: host)
        return sheet
    }

    /// The picker currently presented over `host`, if any.
    public static func current(in host: UIViewController) -> LMKEnumPickerViewController? {
        host.children.last { $0 is LMKEnumPickerViewController } as? LMKEnumPickerViewController
    }

    private static func items<T: Hashable & LMKEnumSelectable>(for options: [T], disabled: Set<T>, showsIcons: Bool) -> [LMKEnumPickerViewController.Item] {
        options.map { option in
            LMKEnumPickerViewController.Item(
                title: option.displayName,
                iconName: showsIcons ? option.iconName : nil,
                isEnabled: !disabled.contains(option)
            )
        }
    }
}

public nonisolated extension LMKTheme {
    /// App-wide default style for `LMKEnumPicker`.
    var enumPicker: LMKEnumPicker.Style {
        get { self[LMKEnumPicker.Style.self] }
        set { self[LMKEnumPicker.Style.self] = newValue }
    }
}
