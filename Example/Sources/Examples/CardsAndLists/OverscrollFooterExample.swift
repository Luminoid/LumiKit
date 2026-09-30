//
//  OverscrollFooterExample.swift
//  LumiKitExample
//
//  Overscroll Footer: A footer revealed by pulling past the end.
//

import LumiKitUI
import SnapKit
import UIKit

// MARK: - Overscroll Footer

final class OverscrollFooterDetailViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private static let cellID = "cell"
    private static let footerHeight: CGFloat = 160

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let footer = LMKOverscrollFooterView(contentView: OverscrollFooterView(), height: OverscrollFooterDetailViewController.footerHeight)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = LMKColor.backgroundPrimary

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: Self.cellID)
        view.addSubview(tableView)
        tableView.snp.makeConstraints { $0.edges.equalToSuperview() }

        // The footer follows the table view on its own and fades in with the pull.
        footer.attach(to: tableView)
        footer.onReveal = { [weak self] in
            guard let self else { return }
            LMKToast.show(.info, "End of list reached", in: self)
        }
    }

    // MARK: - UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        20
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Self.cellID, for: indexPath)
        var config = cell.defaultContentConfiguration()
        config.text = "Row \(indexPath.row + 1)"
        config.secondaryText = "Pull past the bottom to reveal the footer"
        config.image = UIImage(systemName: "\(indexPath.row + 1).circle")
        config.imageProperties.tintColor = LMKColor.primary
        cell.contentConfiguration = config
        return cell
    }

    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - Footer

/// Simple footer shown on overscroll.
private final class OverscrollFooterView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        alpha = 0

        let stack = UIStackView(lmk_axis: .vertical, spacing: LMKSpacing.small)
        stack.alignment = .center

        let config = UIImage.SymbolConfiguration(pointSize: LMKLayout.symbolIllustration, weight: .light)
        let imageView = UIImageView(image: UIImage(systemName: "arrow.down.circle", withConfiguration: config))
        imageView.tintColor = LMKColor.textTertiary
        stack.addArrangedSubview(imageView)

        let label = UILabel.lmk_make(.caption, text: "You've reached the end")
        label.textAlignment = .center
        stack.addArrangedSubview(label)

        addSubview(stack)
        stack.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
