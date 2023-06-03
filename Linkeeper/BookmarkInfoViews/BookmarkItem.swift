//
//  BookmarkView.swift
//  Marked
//
//  Created by Om Chachad on 11/05/22.
//

import SwiftUI
import LinkPresentation

struct BookmarkItem: View {
    @Environment(\.managedObjectContext) var moc
    @Environment(\.openURL) var openURL
    
    @AppStorage("ShadowsEnabled") var shadowsEnabled = true
    @ObservedObject var cache = CacheModel()
    
    var bookmark: Bookmark
    var namespace: Namespace.ID
    @Binding var showDetails: Bool
    @Binding var toBeEditedBookmark: Bookmark?
    
    @State private var deleteConfirmation: Bool = false
    @State private var toBeDeletedBookmark: Bookmark?
    
    @State private var isShimmering = true
    
    @Binding var detailViewImage: DetailsPreview?
    @State private var image: Image?
    @State private var preview = PreviewType.loading
    
    @Environment(\.editMode) var editMode
    @Binding var selectedBookmarks: Set<Bookmark>
    
    @State private var movingBookmark = false
    
    var body: some View {
        VStack(spacing: 0) {
            VStack {
                switch(preview) {

                    case .thumbnail:
                        image!
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .icon:
                        ZStack {
                            Rectangle()
                                .foregroundColor(.white)

                            image!
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        }
                    case .firstLetter:
                        if let firstChar: Character = bookmark.wrappedTitle.first {
                            Color(uiColor: .systemGray2)
                                .overlay(
                                    Text(String(firstChar))
                                        .font(.largeTitle.weight(.medium))
                                        .foregroundColor(.white)
                                        .scaleEffect(2)
                                )
                        }
                    default:
                        Rectangle()
                            .foregroundColor(.secondary.opacity(0.5))
                            .shimmering(active: isShimmering)
                            .clipped()
                }
            }
            .background(Color.secondary.opacity(0.2))
            .matchedGeometryEffect(id: "\(bookmark.wrappedUUID)-Image", in: namespace)
            .frame(minWidth: 140, idealWidth: 300, maxWidth: 300, minHeight: 140, idealHeight: 300, maxHeight: 300)
            .clipped()
            
            
            VStack(alignment: .leading, spacing: 0) {
                Text(bookmark.wrappedTitle)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .matchedGeometryEffect(id: "\(bookmark.wrappedUUID)-Title", in: namespace)
                Text(bookmark.wrappedHost)
                    .lineLimit(1)
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .matchedGeometryEffect(id: "\(bookmark.wrappedUUID)-Host", in: namespace)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 15)
            .padding(.vertical, 10)
        }
        .background(Color(UIColor.systemGray5))
        .aspectRatio(3/4, contentMode: .fill)
        .cornerRadius(15, style: .continuous)
        
        .matchedGeometryEffect(id: "\(bookmark.wrappedUUID)-Background", in: namespace)
        .contextMenu { menuItems() }
        .onTapGesture {
            if editMode?.wrappedValue == .active {
                if selectedBookmarks.contains(bookmark) {
                    
                    selectedBookmarks.remove(bookmark)
                } else {
                    selectedBookmarks.insert(bookmark)
                }
            } else {
                openURL(bookmark.wrappedURL)
            }
        }
        .onLongPressGesture(minimumDuration: 0.1, perform: {
            #if targetEnvironment(macCatalyst)
            detailViewImage = DetailsPreview(image: image, previewState: preview)
            toBeEditedBookmark = bookmark
            showDetails.toggle()
            #endif
        })
        .shadow(color: .black.opacity(0.3), radius: shadowsEnabled ? (selectedBookmarks.contains(bookmark) ? 0 : 3) : 0) // Checks if the shadows are enabled in Settings, otherwise only shows them when the bookmark is not selected.
        .opacity(selectedBookmarks.contains(bookmark) ? 0.75 : 1)
        .padding(selectedBookmarks.contains(bookmark) ? 2.5 : 0)
        .background {
            if selectedBookmarks.contains(bookmark) {
                RoundedRectangle(cornerRadius: 15.5, style: .continuous)
                    .stroke(.blue, lineWidth: 2.5)
            }
        }
        .confirmationDialog("Are you sure you want to delete this bookmark?", isPresented: $deleteConfirmation, titleVisibility: .visible) {
            Button("Delete Bookmark", role: .destructive) {
                moc.delete(bookmark)
                try? moc.save()
            }
        } message: {
            Text("It will be deleted from all your iCloud devices.")
        }
        .sheet(isPresented: $movingBookmark) {
            MoveBookmarksView(toBeMoved: [bookmark])
        }
        .task {
            cache.getImageFor(bookmark: bookmark)
            if let preview = cache.image {
                self.image = Image(uiImage: preview.value)
                self.preview = preview.previewState
                isShimmering = false
            } else {
                do {
                    let metadata = try await startFetchingMetadata(for: bookmark.wrappedURL, fetchSubresources: true, timeout: 15)
                    if let metadata = metadata {
                        let imageProvider = metadata.imageProvider ?? metadata.iconProvider
                        if imageProvider != nil {
                            let imageType: PreviewType = metadata.imageProvider != nil ? .thumbnail : .icon
                            imageProvider!.loadObject(ofClass: UIImage.self) { (image, error) in
                                guard error == nil else {
                                    return
                                }
                                if let image = image as? UIImage {
                                    DispatchQueue.main.async {
                                        self.image = Image(uiImage: image)
                                        preview = imageType
                                        isShimmering = false
                                        cache.saveToCache(image: image, preview: imageType, bookmark: bookmark)
                                    }
                                    return
                                }
                            }
                        }
                    }
                    
                    if preview == .loading {
                        showPlaceHolder()
                    }
                } catch {
                    showPlaceHolder()
                    print("Failed to load data")
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
                if preview == .loading {
                    showPlaceHolder()
                }
            }
        }
        .animation(.default, value: isShimmering)
        .animation(.default, value: selectedBookmarks)
    }
    
    func menuItems() -> some View {
        Group {
            if editMode?.wrappedValue != .active {
                Button {
                    bookmark.isFavorited.toggle()
                    try? moc.save()
                } label: {
                    if bookmark.isFavorited == false {
                        Label("Add to favorites", systemImage: "heart")
                    } else {
                        Label("Remove from favorites", systemImage: "heart.slash")
                    }
                }
                
                Button {
                    detailViewImage = DetailsPreview(image: image, previewState: preview)
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        toBeEditedBookmark = bookmark
                        showDetails.toggle()
                    }
                } label: {
                    Label("Show details", systemImage: "info.circle")
                }
                .disabled(preview == .loading)
                
                Button(action: { copy(bookmark.wrappedURL) }) {
                    Label("Copy link", systemImage: "doc.on.doc")
                }
                
                if #available(iOS 16.0, *) {
                    ShareLink(item: bookmark.wrappedURL) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                } else {
                    Button {
                        share(url: bookmark.wrappedURL)
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                }
                
                Button {
                    movingBookmark.toggle()
                } label: {
                    Label("Move", systemImage: "folder")
                }
                
                Button(role: .destructive) {
                    toBeDeletedBookmark = bookmark
                    deleteConfirmation = true
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }
    
    func showPlaceHolder() {
        preview = .firstLetter
        isShimmering = false
    }
}

func startFetchingMetadata(for url: URL, fetchSubresources: Bool, timeout: TimeInterval?) async throws -> LPLinkMetadata? {
    return try await withCheckedThrowingContinuation { continuation in
        let metadataProvider = LPMetadataProvider()
        metadataProvider.shouldFetchSubresources = fetchSubresources
        metadataProvider.timeout = timeout ?? metadataProvider.timeout
        
        metadataProvider.startFetchingMetadata(for: url) { metadata, error in
            if error != nil {
                continuation.resume(returning: nil)
            } else if let metadata = metadata {
                continuation.resume(returning: metadata)
            } else {
                continuation.resume(returning: nil)
            }
        }
    }
}

func copy(_ url: URL) {
    UIPasteboard.general.url = url
}

func share(url: URL) {
    let activityView = UIActivityViewController(activityItems: [url], applicationActivities: nil)
    
    let allScenes = UIApplication.shared.connectedScenes
    let scene = allScenes.first { $0.activationState == .foregroundActive }
    
    if let windowScene = scene as? UIWindowScene {
        windowScene.keyWindow?.rootViewController?.present(activityView, animated: true, completion: nil)
    }
}

struct DetailsPreview {
    var image: Image?
    var previewState: PreviewType
}
