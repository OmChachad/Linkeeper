//
//  WebViewModel.swift
//  InAppBrowser-SwiftUI
//
//  Created by Diego Dos Santos on 08/08/24.
//

import Foundation
import WebKit
import SwiftUI

final class WebViewModel: NSObject, ObservableObject {

    // MARK: - View State

    @Published private(set) var isLoading = false
    @Published private(set) var loadingProgress: Float = 0
    @Published private(set) var canGoBack = false
    @Published private(set) var canGoForward = false
    @Published private(set) var title: String = ""

    // MARK: - WebView

    weak var webView: WKWebView? {
        didSet {
            tearDownObservers()
            configureWebView()
            setUpObservers()
        }
    }

    // MARK: - Observers

    private var observers: [NSKeyValueObservation] = []

    // MARK: - Public Actions

    func goBack() {
        webView?.goBack()
    }

    func goForward() {
        webView?.goForward()
    }

    func reload() {
        webView?.reload()
    }

    private func configureWebView() {
        webView?.navigationDelegate = self
    }

    private func setUpObservers() {
        guard let webView else { return }

        observers = [
            webView.observe(\.isLoading, options: [.initial, .new]) { [weak self] webView, _ in
                DispatchQueue.main.async {
                    self?.isLoading = webView.isLoading
                }
            },

            webView.observe(\.estimatedProgress, options: [.initial, .new]) { [weak self] webView, _ in
                DispatchQueue.main.async {
                    self?.loadingProgress = Float(webView.estimatedProgress)
                }
            },

            webView.observe(\.canGoBack, options: [.initial, .new]) { [weak self] webView, _ in
                DispatchQueue.main.async {
                    self?.canGoBack = webView.canGoBack
                }
            },

            webView.observe(\.canGoForward, options: [.initial, .new]) { [weak self] webView, _ in
                DispatchQueue.main.async {
                    self?.canGoForward = webView.canGoForward
                }
            },

            webView.observe(\.title, options: [.initial, .new]) { [weak self] webView, _ in
                DispatchQueue.main.async {
                    self?.title = webView.title ?? ""
                }
            }
        ]
    }

    private func tearDownObservers() {
        observers.forEach { $0.invalidate() }
        observers.removeAll()
    }

    deinit {
        tearDownObservers()
    }
}


extension WebViewModel: WKNavigationDelegate {

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        handle(error)
    }

    func webView(_ webView: WKWebView,
                 didFailProvisionalNavigation navigation: WKNavigation!,
                 withError error: Error) {
        handle(error)
    }

    private func handle(_ error: Error) {
        print("WebView error:", error.localizedDescription)
    }
}
