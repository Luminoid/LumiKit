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
        private lazy var session: URLSession = {
            let configuration = URLSessionConfiguration.default
            configuration.lmk_enableNetworkLogging()
            return URLSession(configuration: configuration)
        }()

        private var requestTask: Task<Void, Never>?
        private let readout = UILabel.lmk_make(.caption, text: "No requests sent yet.")

        override func viewDidLoad() {
            super.viewDidLoad()
            if !LMKNetworkLogger.isConfigured {
                LMKNetworkLogger.configure(LMKNetworkLogger.Configuration(maxRecords: 50))
                LMKNetworkLogger.enable()
            }

            addSectionHeader("LMKNetworkLogger")
            stack.addArrangedSubview(UILabel.lmk_make(
                .caption,
                text: "A URLProtocol captures URLSession traffic in DEBUG builds. Authorization, cookie, and API-key headers are replaced with "
                    + "[REDACTED] at capture time, and an optional host filter keeps third-party traffic out of the store."
            ))
            let send = LMKButton(title: "Send sample request", style: .filled(.primary)) { [weak self] in self?.sendSampleRequest() }
            stack.addArrangedSubview(send)
            stack.addArrangedSubview(readout)

            addDivider()
            addSectionHeader("LMKNetworkHistoryViewController")
            stack.addArrangedSubview(UILabel.lmk_make(
                .caption,
                text: "A card page listing the captured requests newest first; rows update in place as responses land, and each opens the full request and response text."
            ))
            let open = LMKButton(title: "Open Network History", style: .outlined(.primary)) { [weak self] in
                self?.navigationController?.pushViewController(LMKNetworkHistoryViewController(), animated: true)
            }
            stack.addArrangedSubview(open)
        }

        isolated deinit {
            requestTask?.cancel()
        }

        private func sendSampleRequest() {
            guard let url = URL(string: "https://example.com/") else { return }
            var request = URLRequest(url: url)
            request.setValue("Bearer demo-token", forHTTPHeaderField: "Authorization")
            readout.text = "Sending…"
            requestTask?.cancel()
            requestTask = Task { [weak self] in
                do {
                    let (_, response) = try await self?.session.data(for: request) ?? (Data(), URLResponse())
                    let status = (response as? HTTPURLResponse)?.statusCode ?? 0
                    self?.readout.text = "Captured \(LMKNetworkLogger.count) request(s); last status \(status). The Authorization header is redacted in the history."
                } catch {
                    self?.readout.text = "Request failed: \(error.localizedDescription). It is still in the history as an error."
                }
            }
        }
    #else
        override func viewDidLoad() {
            super.viewDidLoad()
            addSectionHeader("LumiKitDebug")
            stack.addArrangedSubview(UILabel.lmk_make(.caption, text: "Network logging and the history screen ship in DEBUG builds only."))
        }
    #endif
}
