//
//  NetworkHistoryExample.swift
//  LumiKitExample
//
//  Network History: LMKNetworkLogger capture with redaction, LMKNetworkHistoryViewController.
//

import LumiKitDebug
import LumiKitUI
import UIKit

// MARK: - Network History

final class NetworkHistoryDetailViewController: DetailViewController {
    #if DEBUG
        /// A session whose traffic the logger captures; the logger itself is configured once at
        /// launch (AppDelegate).
        private lazy var session: URLSession = {
            let configuration = URLSessionConfiguration.default
            configuration.lmk_enableNetworkLogging()
            return URLSession(configuration: configuration)
        }()

        private var requestTask: Task<Void, Never>?
        private let readout = UILabel.lmk_make(.caption, text: "No requests sent yet.")

        isolated deinit {
            requestTask?.cancel()
        }

        override func setupStackContent() {
            addSectionHeader("LMKNetworkLogger")
            stackView.addArrangedSubview(UILabel.lmk_make(
                .caption,
                text: "A URLProtocol captures URLSession traffic in DEBUG builds. Authorization, cookie, and API-key headers are replaced with "
                    + "[REDACTED] at capture time, and an optional host filter keeps third-party traffic out of the store. Configure it once at launch."
            ))
            let send = LMKButton(title: "Send sample request", style: .filled(.primary)) { [weak self] in self?.sendSampleRequest() }
            stackView.addArrangedSubview(send)
            stackView.addArrangedSubview(readout)

            addDivider()
            addSectionHeader("LMKNetworkHistoryViewController")
            stackView.addArrangedSubview(UILabel.lmk_make(
                .caption,
                text: "A card page listing the captured requests newest first; rows update in place as responses land, and each opens the full request and response text. "
                    + "Pushed onto a stack that shows its bar, as here, it hands its title and Clear item to that bar; in a card or a stack with a hidden bar it draws its own header."
            ))
            let open = LMKButton(title: "Open Network History", style: .outlined(.primary)) { [weak self] in
                self?.navigationController?.pushViewController(LMKNetworkHistoryViewController(), animated: true)
            }
            stackView.addArrangedSubview(open)
        }

        private func sendSampleRequest() {
            guard let url = URL(string: "https://example.com/") else { return }
            var request = URLRequest(url: url)
            request.setValue("Bearer demo-token", forHTTPHeaderField: "Authorization")
            readout.lmk_setText("Sending…")
            requestTask?.cancel()
            requestTask = Task { [weak self] in
                do {
                    let (_, response) = try await self?.session.data(for: request) ?? (Data(), URLResponse())
                    let status = (response as? HTTPURLResponse)?.statusCode ?? 0
                    self?.readout.lmk_setText("Captured \(LMKNetworkLogger.count) request(s); last status \(status). The Authorization header is redacted in the history.")
                } catch {
                    self?.readout.lmk_setText("Request failed: \(error.localizedDescription). It is still in the history as an error.")
                }
            }
        }
    #else
        override func setupStackContent() {
            addSectionHeader("LumiKitDebug")
            stackView.addArrangedSubview(UILabel.lmk_make(.caption, text: "Network logging and the history screen ship in DEBUG builds only."))
        }
    #endif
}
