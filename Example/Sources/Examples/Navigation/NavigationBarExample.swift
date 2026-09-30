//
//  NavigationBarExample.swift
//  LumiKitExample
//
//  Navigation Bar: Glass on iOS 26, classic before; titles, items, badges.
//

import LumiKitUI
import SnapKit
import UIKit

// MARK: - Navigation Bar

final class NavigationBarDetailViewController: DetailViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        addSectionHeader("Appearance")
        stack.addArrangedSubview(UILabel.lmk_make(
            .caption,
            text: "Style.appearance is .automatic by default: Liquid Glass capsules on iOS 26 (neighbours share one, a prominent item takes its own in the tint, "
                + "no hairline), tinted items over a hairline before. .classic and .glass pin one look; theme.navigationBar sets it app-wide."
        ))
        for (name, appearance) in [("Automatic", LMKNavigationBar.Appearance.automatic), ("Classic", .classic), ("Glass", .glass)] {
            stack.addArrangedSubview(UILabel.lmk_make(.captionMedium, text: name, color: LMKColor.textSecondary))
            let bar = LMKNavigationBar(style: LMKNavigationBar.Style(appearance: appearance))
            bar.title = "Trip"
            bar.showsBackButton = true
            bar.setRightItems([
                .init(identifier: "share", systemName: "square.and.arrow.up", accessibilityLabel: "Share") {},
                .init(identifier: "edit", systemName: "pencil", accessibilityLabel: "Edit") {},
                .init(identifier: "save", title: "Save", role: .prominent) {},
            ])
            wrapInContainer(bar)
        }

        addDivider()
        addSectionHeader("Large Title")
        stack.addArrangedSubview(UILabel.lmk_make(.caption, text: "Bold left-aligned title with button row above. Used on root screens."))

        let largeBar = LMKNavigationBar()
        largeBar.title = "My Items"
        largeBar.largeTitleEnabled = true
        largeBar.setRightItems([
            .init(systemName: "plus", accessibilityLabel: "Add") {},
            .init(systemName: "ellipsis.circle", accessibilityLabel: "More") {},
        ])
        wrapInContainer(largeBar)

        addDivider()
        addSectionHeader("Standard (Inline) Title")
        stack.addArrangedSubview(UILabel.lmk_make(.caption, text: "Centered title with back button. Used on pushed screens."))

        let standardBar = LMKNavigationBar()
        standardBar.title = "Item Details"
        standardBar.showsBackButton = true
        standardBar.setRightItems([
            .init(systemName: "square.and.arrow.up", accessibilityLabel: "Share") {},
        ])
        wrapInContainer(standardBar)

        addDivider()
        addSectionHeader("Left Items")
        stack.addArrangedSubview(UILabel.lmk_make(.caption, text: "Custom left items replace the back button."))

        let leftItemsBar = LMKNavigationBar()
        leftItemsBar.title = "Calendar"
        leftItemsBar.setLeftItems([
            .init(systemName: "sidebar.left", accessibilityLabel: "Sidebar") {},
        ])
        leftItemsBar.setRightItems([
            .init(systemName: "plus", accessibilityLabel: "Add") {},
        ])
        wrapInContainer(leftItemsBar)

        addDivider()
        addSectionHeader("Custom Colors")
        stack.addArrangedSubview(UILabel.lmk_make(.caption, text: "Customizable background, title color, and button tint."))

        let customBar = LMKNavigationBar(style: LMKNavigationBar.Style(
            surface: LMKSurfaceStyle(background: .solid(LMKColor.primary)),
            tintColor: LMKColor.onAccent,
            largeTitleColor: LMKColor.onAccent,
            showsSeparator: false
        ))
        customBar.title = "Settings"
        customBar.largeTitleEnabled = true
        customBar.setRightItems([
            .init(systemName: "gearshape", accessibilityLabel: "Settings") {},
        ])
        wrapInContainer(customBar, background: LMKColor.primary)

        addDivider()
        addSectionHeader("Subtitle, Roles, and Badges")
        stack.addArrangedSubview(UILabel.lmk_make(
            .caption,
            text: "subtitle adds a caption under either title. Items carry a role (.plain, .prominent, .destructive), "
                + "an optional menu, and a badge; give them an identifier and change one later with updateItem(_:_:)."
        ))

        let rolesBar = LMKNavigationBar()
        rolesBar.title = "Inbox"
        rolesBar.subtitle = "3 unread"
        rolesBar.showsBackButton = true
        rolesBar.setRightItems([
            .init(identifier: "more", systemName: "ellipsis.circle", accessibilityLabel: "More", menu: UIMenu(children: [
                UIAction(title: "Mark all read") { _ in },
                UIAction(title: "Archive", attributes: .destructive) { _ in },
            ])),
            .init(identifier: "compose", systemName: "square.and.pencil", accessibilityLabel: "Compose", badge: .count(3)) { [weak rolesBar] in
                rolesBar?.updateItem("compose") { $0.badge = nil }
            },
            .init(identifier: "done", title: "Done", role: .prominent) {},
        ])
        wrapInContainer(rolesBar)

        addDivider()
        addSectionHeader("No Separator")
        stack.addArrangedSubview(UILabel.lmk_make(.caption, text: "style.showsSeparator = false for clean content-heavy screens."))

        let noSepBar = LMKNavigationBar()
        noSepBar.title = "Photos"
        noSepBar.style.showsSeparator = false
        noSepBar.setRightItems([
            .init(systemName: "camera", accessibilityLabel: "Camera") {},
        ])
        wrapInContainer(noSepBar)

        addDivider()
        addSectionHeader("Right Accessory View")
        stack.addArrangedSubview(UILabel.lmk_make(.caption, text: "Place a non-tappable view (sync indicator, status icon) "
                + "to the left of the right items via setRightAccessoryView(_:). "
                + "It survives later setRightItems(_:) calls."))

        let accessoryBar = LMKNavigationBar()
        accessoryBar.title = "Inbox"
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.color = LMKColor.textSecondary
        spinner.startAnimating()
        accessoryBar.setRightAccessoryView(spinner)
        accessoryBar.setRightItems([
            .init(systemName: "square.and.pencil", accessibilityLabel: "Compose") {},
        ])
        wrapInContainer(accessoryBar)

        addDivider()
        addSectionHeader("Large Title Accessory")
        stack.addArrangedSubview(UILabel.lmk_make(.caption, text: "iOS Mail / Notes pattern: hang an inline accessory off the "
                + "trailing edge of the large title via setLargeTitleAccessoryView(_:). "
                + "Useful for sync state next to a section title."))

        let titleAccessoryBar = LMKNavigationBar()
        titleAccessoryBar.title = "Pets"
        titleAccessoryBar.largeTitleEnabled = true
        let cloudIcon = UIImageView(image: UIImage(systemName: "icloud"))
        cloudIcon.tintColor = LMKColor.textSecondary
        cloudIcon.contentMode = .scaleAspectFit
        cloudIcon.snp.makeConstraints { make in
            make.width.height.equalTo(LMKLayout.iconMedium)
        }
        titleAccessoryBar.setLargeTitleAccessoryView(cloudIcon)
        wrapInContainer(titleAccessoryBar)
    }

    private func wrapInContainer(_ bar: LMKNavigationBar, background: UIColor? = nil) {
        let container = UIView()
        container.backgroundColor = background ?? LMKColor.backgroundSecondary
        container.layer.cornerRadius = LMKCornerRadius.medium
        container.clipsToBounds = true
        container.addSubview(bar)
        bar.snp.makeConstraints { $0.edges.equalToSuperview() }
        stack.addArrangedSubview(container)
    }
}
