//
//  BookmarkGridItem.swift
//  Marked
//
//  Created by Om Chachad on 11/05/22.
//

import SwiftUI
import LinkPresentation
import Pow
import Shimmer

struct BookmarkGridItem: View {
    @Environment(\.managedObjectContext) var moc
    @Environment(\.openURL) var openURL
    
    @AppStorage("ShadowsEnabled") var shadowsEnabled = true
    
    var bookmark: Bookmark
    var namespace: Namespace.ID
    @Binding var showDetails: Bool
    @Binding var toBeEditedBookmark: Bookmark?
    
    @State private var deleteConfirmation: Bool = false
    @State private var toBeDeletedBookmark: Bookmark?
    
    @State private var cachedPreview: cachedPreview?
    
    @Environment(\.editMode) var editMode
    @Binding var selectedBookmarks: Set<Bookmark.ID>
    
    @State private var movingBookmark = false
    
    var isSelected: Bool {
        selectedBookmarks.contains(bookmark.id ?? UUID())
    }
    
    var isEditing: Bool {
        #if os(macOS)
        return self._editMode.wrappedValue == .active
        #else
        return self.editMode?.wrappedValue == .active
        #endif
    }
    
    init(bookmark: Bookmark, namespace: Namespace.ID, showDetails: Binding<Bool>, toBeEditedBookmark: Binding<Bookmark?>, selectedBookmarks: Binding<Set<Bookmark.ID>>) {
        self.bookmark = bookmark
        self.namespace = namespace
        self._showDetails = showDetails
        self._toBeEditedBookmark = toBeEditedBookmark
        self._selectedBookmarks = selectedBookmarks
        
        #if !os(macOS)
        let cacheManager = CacheManager.instance
        
        self._cachedPreview = State(initialValue: cacheManager.get(for: bookmark))
        #endif
    }
    
    var body: some View {
        VStack(spacing: 0) {
            VStack {
                switch(cachedPreview?.previewState) {
                case .thumbnail, .icon:
                    cachedPreview!.image?
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .drawingGroup()
                case .firstLetter:
                    if let firstChar: Character = bookmark.wrappedTitle.first {
                        Color(.gray)
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
            .frame(minWidth: 140, idealWidth: 300, maxWidth: 300, minHeight: 100, idealHeight: 300, maxHeight: 300)
            .clipped()
            .contentShape(Rectangle())
            .overlay(alignment: .topTrailing) {
                if !bookmark.wrappedNotes.isEmpty {
                    Image(systemName: "text.alignright")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(10)
                        .background {
                            Rectangle()
                                .fill(LinearGradient(colors: [.black, .clear], startPoint: .topTrailing , endPoint: .bottomLeading))
                                .blur(radius: 10)
                                .padding([.top, .trailing], -15)
                        }
                }
            }
            
            
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
        #if os(visionOS)
        .background(Color.black.opacity(0.4))
        .drawingGroup()
        #else
        #if os(macOS)
        .background(Color("GridItemBackground").opacity(0.35))
        #else
        .background(Color(UIColor.systemGray5))
        #endif
        #endif
        .aspectRatio(3/4, contentMode: .fill)
        .cornerRadius(15, style: .continuous)
        #if !os(macOS)
        .contentShape(.hoverEffect, .rect(cornerRadius: 15))
        .hoverEffect(.lift)
        #endif
        .matchedGeometryEffect(id: "\(bookmark.wrappedUUID)-Background", in: namespace)
        .contextMenu { menuItems() }
        .onTapGesture {
            if isEditing {
                if isSelected {
                    selectedBookmarks.remove(bookmark.id ?? UUID())
                } else {
                    selectedBookmarks.insert(bookmark.id ?? UUID())
                }
            } else {
                openBookmark()
            }
        }
        .contextMenu { menuItems() }
        .onLongPressGesture(minimumDuration: 0.5, perform: {
            #if os(macOS)
                toBeEditedBookmark = bookmark
                showDetails.toggle()
            #endif
        })
        .draggable(bookmark)
        .shadow(color: .black.opacity(0.2), radius: shadowsEnabled ? (isSelected ? 0 : 2) : 0) // Checks if the shadows are enabled in Settings, otherwise only shows them when the bookmark is not selected.
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
                BookmarksManager.shared.deleteBookmark(bookmark)
                try? moc.save()
            }
        } message: {
            Text("It will be deleted from all your iCloud devices.")
        }
        .sheet(isPresented: $movingBookmark) {
            MoveBookmarksView(toBeMoved: [bookmark]) {}
        }
        .task {
            if cachedPreview == nil {
                bookmark.cachedImage(saveTo: $cachedPreview)
            }
        }
        .animation(.default, value: selectedBookmarks)
        .animation(.default, value: bookmark.wrappedTitle)
        .animation(.default, value: cachedPreview?.previewState)
        .if(toBeDeletedBookmark != nil) { view in
            view.transition(.movingParts.poof)
        }
    }
    
    func menuItems() -> some View {
        Group {
            if !isEditing {
                Button {
                    bookmark.isFavorited.toggle()
                    try? moc.save()
                } label: {
                    if bookmark.isFavorited == false {
                        ModernLabel("Add to favorites", systemImage: "heart")
                    } else {
                        ModernLabel("Remove from favorites", systemImage: "heart.slash")
                    }
                }
                
                Button("Show details", systemImage: "info.circle") {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation {
                            toBeEditedBookmark = bookmark
                            showDetails = true
                        }
                    }
                }
                .labelStyle(.titleAndIcon)
                
                Button("Copy link", systemImage: "doc.on.doc", action: bookmark.copyURL)
                .labelStyle(.titleAndIcon)
                
                ShareButton(url: bookmark.wrappedURL) {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .labelStyle(.titleAndIcon)
                }
                
                Button("Move", systemImage: "folder") {
                    movingBookmark.toggle()
                }
                .labelStyle(.titleAndIcon)
                
                Button("Delete", systemImage: "trash", role: .destructive) {
                    toBeDeletedBookmark = bookmark
                    deleteConfirmation = true
                }
                .labelStyle(.titleAndIcon)
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
