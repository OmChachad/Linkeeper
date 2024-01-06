//
//  BookmarksTableView.swift
//  Linkeeper
//
//  Created by Om Chachad on 05/01/24.
//

import SwiftUI

@available(iOS 16.0, *)
struct BookmarksTableView: View {
    @Environment(\.openURL) var openURL
    var bookmarks: [Bookmark]
    
    @Binding var selectedBookmarks: Set<Bookmark.ID>
    @Binding var sortOrder: [KeyPathComparator<Bookmark>]
    
    @Binding var toBeEditedBookmark: Bookmark?
    @Binding var showDetails: Bool
    
    @State private var toBeMovedBookmark: Bookmark?
    @State private var isMoving = false
    
    @State private var toBeDeletedBookmark: Bookmark?
    @State private var deleteConfirmation = false
    
    
    var body: some View {
        Table(of: Bookmark.self, selection: $selectedBookmarks, sortOrder: $sortOrder) {
            TableColumn("Name", value: \.wrappedTitle) { bookmark in
                TableNameView(bookmark: bookmark)
            }
            .width(min: 200)
            
            TableColumn("Host", value: \.wrappedHost)
                .width(max: 200)
            
            TableColumn("Folder", value: \.wrappedFolderName)
                .width(max: 200)
            
            TableColumn("Date Added", value: \.wrappedDate) { bookmark in
                Text(bookmark.wrappedDate, style: .date)
                    .tag(bookmark.wrappedDate)
            }
            .width(max: 150)
        } rows: {
            ForEach(bookmarks.sorted(using: sortOrder)) { bookmark in
                Group {
                    if #available(iOS 17.0, *) {
                        TableRow(bookmark)
                            .draggable(bookmark.draggable)
                    } else {
                        TableRow(bookmark)
                    }
                }
                .contextMenu {
                    Group {
                        Button {
                            openURL(bookmark.wrappedURL)
                        } label: {
                            Label("Open in browser", systemImage: "safari")
                        }
                        
                        Divider()
                        
                        Button {
                            bookmark.isFavorited.toggle()
                        } label: {
                            if bookmark.isFavorited == false {
                                Label("Add to favorites", systemImage: "heart")
                            } else {
                                Label("Remove from favorites", systemImage: "heart.slash")
                            }
                        }
                        
                        Button {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                withAnimation {
                                    toBeEditedBookmark = bookmark
                                    showDetails = true
                                }
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
                        
                        Button(role: .destructive) {
                            toBeDeletedBookmark = bookmark
                            deleteConfirmation = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .confirmationDialog("Are you sure you want to delete this bookmark?", isPresented: $deleteConfirmation, titleVisibility: .visible) {
            Button("Delete Bookmark", role: .destructive) {
                BookmarksManager.shared.deleteBookmark(toBeDeletedBookmark!)
            }
        } message: {
            Text("It will be deleted from all your iCloud devices.")
        }
    }
}

struct TableNameView: View {
    var bookmark: Bookmark
    
    var cachedPreview: cachedPreview? {
        return CacheManager.instance.get(for: bookmark)
    }
    
    var body: some View {
        HStack {
            Group {
                if let preview = cachedPreview?.image {
                    preview
                        .resizable()
                        .scaledToFit()
                } else if let firstChar = bookmark.wrappedTitle.first {
                    Text(String(firstChar))
                        .font(.title)
                        .frame(width: 44, height: 44)
                        .background(.tertiary)
                }
            }
            .scaledToFill()
            .frame(width: 44, height: 44)
            .clipped()
            .cornerRadius(8, style: .continuous)
            .padding(.vertical, 5)
            .padding(.trailing, 10)
            
            Text(bookmark.wrappedTitle)
        }
        .task {
            bookmark.cachedImage(saveTo: .constant(nil)) // To refresh the cachedPreview
        }
    }
}

//struct BookmarkTableItemView: View {
//    @Environment(\.managedObjectContext) var moc
//    @Environment(\.editMode) var editMode
//    @Environment(\.openURL) var openURL
//
//    var bookmark: Bookmark
//
//    @Binding var showDetails: Bool
//    @Binding var toBeEditedBookmark: Bookmark?
//
//    @State private var deleteConfirmation: Bool = false
//    @State private var toBeDeletedBookmark: Bookmark?
//
//    //@Binding var detailViewImage: cachedPreview?
//    @State private var cachedPreview: cachedPreview?
//
//    //@Binding var selectedBookmarks: Set<Bookmark.ID>
//
//    @State private var movingBookmark = false
//
//    @State private var isFavorited = false
//
//    var body: some View {
//        Group {
//            if #available(iOS 17.0, *) {
//                TableRow(bookmark)
//                    //.draggable(bookmark.draggable)
//            } else {
//                TableRow(bookmark)
//            }
//        }
//        .contextMenu {
//            Button("Show Details") {
//                toBeEditedBookmark = bookmark
//                showDetails = true
//            }
//            //                    Button("Delete", role: .destructive) {
//            //                        toBe
//            //                    }
//        }
//    }
//}

//#Preview {
//    BookmarksTableView()
//}
