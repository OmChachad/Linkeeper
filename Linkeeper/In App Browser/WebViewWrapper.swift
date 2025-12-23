//
//  WebViewWrapper.swift
//  InAppBrowser-SwiftUI
//
//  Created by Diego Dos Santos on 02/08/24.
//

import SwiftUI
import WebKit
#if os(macOS)
import SwiftUI
import WebKit

struct WebViewWrapper: NSViewRepresentable {

    // MARK: - Public vars
    let url: URL
    @ObservedObject var viewModel: WebViewModel

    // MARK: - NSViewRepresentable

    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView()

        viewModel.webView = webView
        webView.load(URLRequest(url: url))

        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) { }
}

#else
struct WebViewWrapper: UIViewRepresentable {

    // MARK: - Public vars
    var url: URL
    @ObservedObject var viewModel: WebViewModel

    // MARK: - UIViewRepresentable

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        viewModel.webView = webView

        // Load initial URL
        webView.load(URLRequest(url: url))

        // Add pull-to-refresh
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(
            context.coordinator,
            action: #selector(Coordinator.handleRefresh),
            for: .valueChanged
        )
        webView.scrollView.refreshControl = refreshControl
        
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) { }

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }

    // MARK: - Coordinator

    class Coordinator: NSObject {
        let viewModel: WebViewModel

        init(viewModel: WebViewModel) {
            self.viewModel = viewModel
        }

        @objc func handleRefresh(_ sender: UIRefreshControl) {
            viewModel.webView?.reload()

            // End refreshing after reload starts
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                sender.endRefreshing()
            }
        }
    }
}
#endif
