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
    
    var bookmark: Bookmark
    var namespace: Namespace.ID
    @Binding var showDetails: Bool
    @Binding var toBeEditedBookmark: Bookmark?
    
    @State private var deleteConfirmation: Bool = false
    @State private var toBeDeletedBookmark: Bookmark?
    
    //@Binding var detailViewImage: cachedPreview?
    @State private var cachedPreview: cachedPreview?
    
    @Environment(\.editMode) var editMode
    @Binding var selectedBookmarks: Set<Bookmark>
    
    @State private var movingBookmark = false
    
    var isSelected: Bool {
        selectedBookmarks.contains(bookmark)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            VStack {
                switch(cachedPreview?.previewState) {
                case .thumbnail, .icon:
                    cachedPreview!.image!
                        .resizable()
                        .aspectRatio(contentMode: .fill)
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
                        .shimmering()
                }
            }
            .matchedGeometryEffect(id: "\(bookmark.wrappedUUID)-Image", in: namespace)
            .frame(minWidth: 140, idealWidth: 300, maxWidth: 300, minHeight: 140, idealHeight: 300, maxHeight: 300)
            .clipped()
            .contentShape(Rectangle())
            
            
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
                if isSelected {
                    selectedBookmarks.remove(bookmark)
                } else {
                    selectedBookmarks.insert(bookmark)
                }
            } else {
                openBookmark()
            }
        }
        .contextMenu { menuItems() }
        .onLongPressGesture(minimumDuration: 0.1, perform: {
            #if targetEnvironment(macCatalyst)
                toBeEditedBookmark = bookmark
                showDetails.toggle()
            #endif
        })
        .draggable(bookmark)
        .shadow(color: .black.opacity(0.3), radius: shadowsEnabled ? (isSelected ? 0 : 3) : 0) // Checks if the shadows are enabled in Settings, otherwise only shows them when the bookmark is not selected.
        .opacity(isSelected ? 0.75 : 1)
        .padding(isSelected ? 2.5 : 0)
        .background {
            if isSelected {
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
            bookmark.cachedImage(saveTo: $cachedPreview)
        }
        .animation(.default, value: selectedBookmarks)
        .animation(.default, value: bookmark.wrappedTitle)
        .animation(.default, value: cachedPreview?.previewState)
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
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        toBeEditedBookmark = bookmark
                        showDetails.toggle()
                    }
                } label: {
                    Label("Show details", systemImage: "info.circle")
                }
                
                Button(action: bookmark.copyURL) {
                    Label("Copy link", systemImage: "doc.on.doc")
                }
                
                ShareButton(url: bookmark.wrappedURL) {
                    Label("Share", systemImage: "square.and.arrow.up")
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
    
    func openBookmark() {
        openURL(bookmark.wrappedURL)
        Task {
            await bookmark.cachePreviewInto($cachedPreview)
        }
    }
}
