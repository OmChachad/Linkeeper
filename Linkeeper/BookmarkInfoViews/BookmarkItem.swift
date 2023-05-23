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
        .shadow(color: .secondary.opacity(0.5), radius: selectedBookmarks.contains(bookmark) ? 0 : 3)
        .opacity(selectedBookmarks.contains(bookmark) ? 0.75 : 1)
        .padding(selectedBookmarks.contains(bookmark) ? 2.5 : 0)
        .background {
            if selectedBookmarks.contains(bookmark) {
                RoundedRectangle(cornerRadius: 15.5, style: .continuous)
                    .stroke(.blue, lineWidth: 2.5)
            }
        }
        .contextMenu { menuItems() }
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
                    let metadata = try await startFetchingMetadata(for: bookmark.wrappedURL)
                    
                    if let imageProvider = metadata.imageProvider {
                        imageProvider.loadObject(ofClass: UIImage.self) { (image, error) in
                            guard error == nil else {
                                //showPlaceHolder()
                                return
                            }
                            if let image = image as? UIImage {
                                DispatchQueue.main.async {
                                    self.image = Image(uiImage: image)
                                    preview = .thumbnail
                                    isShimmering = false
                                    cache.saveToCache(image: image, preview: .thumbnail, bookmark: bookmark)
                                }
                            }
                        }
                    } else if let iconImageProvider = metadata.iconProvider {
                        iconImageProvider.loadObject(ofClass: UIImage.self) { (iconImage, error) in
                            guard error == nil else {
                                //showPlaceHolder()
                                return
                            }
                            if let image = iconImage as? UIImage {
                                DispatchQueue.main.async {
                                    self.image = Image(uiImage: image)
                                    preview = .icon
                                    isShimmering = false
                                    cache.saveToCache(image: image, preview: .icon, bookmark: bookmark)
                                }
                            }
                        }
                    } else {
                        showPlaceHolder()
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
    
    func showPlaceHolder() {
        preview = .firstLetter
        isShimmering = false
    }
    
    func startFetchingMetadata(for URL: URL) async throws -> LPLinkMetadata {
        let metadataProvider = LPMetadataProvider()
        
        do {
            return try await metadataProvider.startFetchingMetadata(for: URL)
        } catch {
            return LPLinkMetadata()
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
