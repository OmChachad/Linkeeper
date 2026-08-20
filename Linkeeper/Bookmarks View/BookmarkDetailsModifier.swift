//
//  BookmarkDetailsModifier.swift
//  Linkeeper
//

import SwiftUI

/// Presents bookmark details using the platform-appropriate presentation.
private struct BookmarkDetailsModifier: ViewModifier {
    @Binding private var item: Bookmark?
    private let namespace: Namespace.ID
    private let hidesFavoriteOption: Bool
    private let overlayTransition: AnyTransition?

    /// Creates a bookmark-details presentation modifier.
    init(
        item: Binding<Bookmark?>,
        namespace: Namespace.ID,
        hidesFavoriteOption: Bool,
        overlayTransition: AnyTransition?
    ) {
        _item = item
        self.namespace = namespace
        self.hidesFavoriteOption = hidesFavoriteOption
        self.overlayTransition = overlayTransition
    }

    func body(content: Content) -> some View {
        #if os(visionOS)
        content
            .ornament(
                visibility: item == nil ? .hidden : .visible,
                attachmentAnchor: .scene(.trailing),
                contentAlignment: .leading
            ) {
                if let bookmark = item {
                    BookmarkDetails(
                        bookmark: bookmark,
                        namespace: namespace,
                        presentedBookmark: $item,
                        hideFavoriteOption: hidesFavoriteOption
                    )
                }
            }
        #else
        content
            .overlay {
                if let bookmark = item {
                    if #available(macOS 26.0, iOS 26.0, *) {
                        Rectangle()
                            .glassEffect(.regular.interactive(), in: .rect)
                            .ignoresSafeArea()
                            .onTapGesture {
                                item = nil
                            }
                    } else {
                        Color("primaryInverted").opacity(0.3)
                            .background(.thinMaterial)
                            .ignoresSafeArea()
                            .onTapGesture {
                                item = nil
                            }
                    }

                    BookmarkDetails(
                        bookmark: bookmark,
                        namespace: namespace,
                        presentedBookmark: $item,
                        hideFavoriteOption: hidesFavoriteOption
                    )
                    .if(overlayTransition != nil) {
                        $0
                            .transition(overlayTransition!)
                    }
                }
            }
        #endif
    }
}

extension View {
    /// Presents details for a bookmark over the modified view.
    ///
    /// The presentation uses an overlay on iOS and macOS and an ornament on visionOS.
    /// The details are shown while `item` is non-`nil`, and dismissal sets it to `nil`.
    ///
    /// - Parameters:
    ///   - item: A binding to the bookmark whose details are presented.
    ///   - namespace: The namespace used for matched-geometry transitions.
    ///   - hidesFavoriteOption: Whether the favorite action is hidden.
    ///   - overlayTransition: The transition applied to the iOS and macOS details overlay.
    /// - Returns: A view that can present bookmark details.
    func bookmarkDetails(
        item: Binding<Bookmark?>,
        namespace: Namespace.ID,
        hidesFavoriteOption: Bool = false,
        overlayTransition: AnyTransition?
    ) -> some View {
        modifier(
            BookmarkDetailsModifier(
                item: item,
                namespace: namespace,
                hidesFavoriteOption: hidesFavoriteOption,
                overlayTransition: overlayTransition
            )
        )
    }
}
