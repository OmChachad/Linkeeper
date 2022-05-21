//
//  BookmarksView.swift
//  Marked
//
//  Created by Om Chachad on 08/05/22.
//

import SwiftUI

struct BookmarksView: View {
    var folder: Folder?
    @ObservedObject var bookmarks: Bookmarks
    @ObservedObject var folders: Folders
    
    @State private var addingBookmark = false
    @State private var searchText = ""
    
    
    @State private var deleteConfirmation = false
    
    @State private var toBeDeleted: [Bookmark]?
    @State var mode: EditMode = .inactive
    
    @State private var wiggleAmount = 0.0
    
    var columns: [GridItem] {
        if UIDevice.current.model == "iPhone" {
            return [UIScreen.main.bounds.width == 320  ? GridItem(.adaptive(minimum: 130, maximum: 180), spacing: 20) : GridItem(.adaptive(minimum: 150, maximum: 180), spacing: 20)]
        } else {
                return [GridItem(.adaptive(minimum: 170, maximum: 180), spacing: 20)]
        }
    }
    
    var body: some View {
        ZStack {
            if allBookmarks.count == 0 {
                Text("""
                    You do not have any bookmarks\(folder != nil ? " in this folder" : "")
                    Click \(Image(systemName: "plus")) to add one
                    """)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(alignment: .center)
            } else {
                ScrollView {
          //          LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: columns(geometry: geometry)), spacing: 10) {
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(filteredBookmarks, id:\.self) { bookmark in
                            //MARK: For Wiggle Mode
                            // Group {
//                                if mode == .inactive {
//                                    BookmarkView(vm: LinkViewModel(url: bookmark.url), bookmark: bookmark)
//                                } else {
//                                    BookmarkView(vm: LinkViewModel(url: bookmark.url), bookmark: bookmark)
//                                        .rotationEffect(.degrees(wiggleAmount))
////                                        .onAppear {
////                                            withAnimation(.easeInOut.speed(3).repeatForever(autoreverses: true)) {
////                                                wiggleAmount = 1.5
////                                            }
////                                        }
//                                }
//                            }
                            BookmarkView(vm: LinkViewModel(url: bookmark.url), bookmark: bookmark)
                              //  .shadow(color: .secondary.opacity(0.5), radius: 3) // MARK: Make this optional in settings
                                .if(mode == .active) { view in
                                    view.rotationEffect(.degrees(wiggleAmount))
                                }
                            
                                .transition(.opacity)
                               // .frame(minWidth: 130, idealWidth: 180, maxWidth: 180)
                                .frame(minHeight: 156, idealHeight: 218.2, maxHeight: 218.2)
                                .contextMenu {
//                                    if folder != nil {
//                                        Button {
//                                            var pinnedBookmark = bookmark
//                                            pinnedBookmark.isPinned.toggle()
//                                            let index = indexOf(bookmark: bookmark, folder: nil)!
//                                            bookmarks.items.remove(at: index)
//                                            bookmarks.items.insert(pinnedBookmark, at: index)
//
//                                        } label: {
//                                            if bookmark.isPinned == false {
//                                                Label("Pin", systemImage: "pin")
//                                            } else {
//                                                Label("Unpin", systemImage: "pin.slash")
//                                            }
//                                        }
//                                    }
                                    
                                    Button {
                                        // Code to edit the bookmark
                                    } label: {
                                        Label("Show details", systemImage: "info.circle")
                                    }
                                    
                                    Button {
                                        UIPasteboard.general.url = bookmark.url
                                    } label: {
                                        Label("Copy link", systemImage: "doc.on.doc")
                                    }
                                    
                                    Button {
                                        share(url: bookmark.url)
                                    } label: {
                                        Label("Share", systemImage: "square.and.arrow.up")
                                    }
                                    
                                    Button {
                                        // Code to move
                                    } label: {
                                        Label("Move", systemImage: "folder")
                                    }
                                    
                                    Button(role: .destructive) {
                                        toBeDeleted = [bookmark]
                                        deleteConfirmation = true
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .searchable(text: $searchText, prompt: "Find a bookmark...")
                    .padding(.horizontal)
                    }
                }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if mode == .inactive {
            Menu {
                Button {
                    mode = .active
                } label: {
                    Label("Select", systemImage: "checkmark.circle")
                }
                
                Button {
                    addingBookmark = true
                } label: {
                    Label("Add Bookmark", systemImage: "plus")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            } else {
                Button("Done") {
                    mode = .inactive
                }
            }
            
        }
        .environment(\.editMode, $mode)
        .sheet(isPresented: $addingBookmark) {
            AddBookmarkView(bookmarks: bookmarks, folders: folders, folderPreset: folder)
        }
        .confirmationDialog("Are you sure you want to delete \(toBeDeleted?.count == 1 ? "this bookmark? It" : "these bookmarks? They") will be deleted from all your iCloud devices.", isPresented: $deleteConfirmation, titleVisibility: .visible) {
            Button(toBeDeleted?.count == 1 ? "Delete" : "Delete \(toBeDeleted != nil ? toBeDeleted!.count : 0) Bookmarks", role: .destructive) {
                guard let toBeDeleted = toBeDeleted else {
                    return
                }
                
                for bookmark in toBeDeleted {
                    bookmarks.items.remove(at: bookmarks.items.firstIndex(of: bookmark)!)
                }
                self.toBeDeleted = nil
            }
        }
        .animation(.spring(), value: filteredBookmarks)
        .onChange(of: mode) { newValue in
            if newValue == .inactive {
                wiggleAmount = 0
            } else {
                withAnimation(.easeInOut.speed(3).repeatForever(autoreverses: true)) {
                    wiggleAmount = 1.5
                }
            }
        }
    }
    
    var allBookmarks: [Bookmark] {
        return bookmarks.items.filter({ if folder != nil { return $0.folder == folder } else { return true } })
    }
    
    func indexOf(bookmark: Bookmark?, folder: Folder?) -> Int? {
        if let index = bookmarks.items.firstIndex(of: bookmark!) {
            return index
        } else if let index = folders.items.firstIndex(of: folder!) {
            return index
        } else {
            return nil
        }
    }
    
    func columns(geometry: GeometryProxy) -> Int {
        if Int(round(geometry.size.width/218.2)) >= 2 {
            return Int(round(geometry.size.width/218.2))
        } else {
            return 2
        }
    }
    var filteredBookmarks: [Bookmark] {
        let allBookmarks = bookmarks.items.filter({ if folder != nil { return $0.folder == folder } else { return true } })
        if folder == nil {
            return allBookmarks
        } else if searchText.isEmpty {
            return allBookmarks.sorted{ $0.isPinned && !$1.isPinned }
        } else {
            return allBookmarks.filter { $0.title.localizedCaseInsensitiveContains(searchText) || $0.notes.localizedCaseInsensitiveContains(searchText) || $0.host.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    func share(url: URL) {
        let activityView = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        
        let allScenes = UIApplication.shared.connectedScenes
        let scene = allScenes.first { $0.activationState == .foregroundActive }
        
        if let windowScene = scene as? UIWindowScene {
            windowScene.keyWindow?.rootViewController?.present(activityView, animated: true, completion: nil)
        }
    }
    
    func makeView(_ geometry: GeometryProxy) -> some View {
            print(geometry.size.width, geometry.size.height)

            //DispatchQueue.main.async { self.frame = geometry.size }

            return Text("Test")
                    .frame(width: geometry.size.width)
        }
    
}

struct BookmarksView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            BookmarksView(bookmarks: Bookmarks(), folders: Folders())
        }
    }
}


//extension View {
//    public func wiggle<Content: View>(isWiggling: Binding<Bool>, wiggleAmmount: Binding<Double>) -> some View {
//        return Group {
//            if isWiggling.wrappedValue == true {
//                self
//                    .rotation3DEffect(.degrees(wiggleAmmount.wrappedValue), axis: .center)
//            } else {
//                self
//            }
//        }
//    }
//}

extension View {
    /// Applies the given transform if the given condition evaluates to `true`.
    /// - Parameters:
    ///   - condition: The condition to evaluate.
    ///   - transform: The transform to apply to the source `View`.
    /// - Returns: Either the original `View` or the modified `View` if the condition is `true`.
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}


