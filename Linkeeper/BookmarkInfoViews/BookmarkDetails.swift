//
//  BookmarkDetails.swift
//  Linkeeper
//
//  Created by Om Chachad on 27/05/22.
//

import SwiftUI
import LinkPresentation
import Shimmer
import Pow

struct BookmarkDetails: View {
    @Environment(\.managedObjectContext) var moc
    @Environment(\.openURL) var openURL
    @Environment(\.keyboardShortcut) var keyboardShortcut
    
    var bookmark: Bookmark
    var namespace: Namespace.ID
    @Binding var showDetails: Bool
    
    @State private var title = ""
    @State private var notes = ""
    @State private var isFavorited = false
    @State private var editing = false
    
    @State private var hideFavoriteOption = false
    
    @State private var isShimmering = true
    
    @State private var cachedPreview: cachedPreview?
    
    @State private var deleteConfirmation = false
    
    init(bookmark: Bookmark, namespace: Namespace.ID, showDetails: Binding<Bool>, hideFavoriteOption: Bool = false) {
        self.bookmark = bookmark
        self.namespace = namespace
        _showDetails = showDetails
        _title = State(initialValue: bookmark.wrappedTitle)
        _notes = State(initialValue: bookmark.wrappedNotes)
        _isFavorited = State(initialValue: bookmark.isFavorited)
        _hideFavoriteOption = State(initialValue: hideFavoriteOption)
    }
    
    var body: some View {
        VStack {
            Flashcard(editing: $editing) {
                frontView()
            } back: {
                backView()
                    .frame(maxHeight: 400)
            }
        }
        .shadow(color: .black.opacity(0.25), radius: 10)
        .padding(10)
    }
    
    func frontView() -> some View {
        VStack(spacing: 0) {
            thumbnail()
                .matchedGeometryEffect(id: "\(bookmark.wrappedUUID)-Image", in: namespace)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: hideFavoriteOption ? 4 : 5)) {
                actionButtons()
                    .padding(7.5)
                    .hoverEffect(.highlight)
            }
            .font(.title2)
            .padding(2.5)
            .background(Color(.systemGray4))
            .buttonStyle(.borderless)
            
            AdaptiveScrollView(notes: bookmark.wrappedNotes) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(bookmark.wrappedTitle)
                        .matchedGeometryEffect(id: "\(bookmark.wrappedUUID)-Title", in: namespace)
                    Text(bookmark.wrappedHost)
                        .font(.callout)
                        .foregroundColor(.secondary)
                        .matchedGeometryEffect(id: "\(bookmark.wrappedUUID)-Host", in: namespace)
                    
                    if !bookmark.wrappedNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Spacer()
                            .frame(height: 20)
                        
                        Text("NOTES")
                            .foregroundColor(.secondary)
                            .font(.headline)
                        Text(bookmark.wrappedNotes)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
            }
        }
        .background(.ultraThinMaterial)
        .cornerRadius(15, style: .continuous)
        .matchedGeometryEffect(id: "\(bookmark.wrappedUUID)-Background", in: namespace)
        .overlay(alignment: .topTrailing) {
            Button {
                showDetails = false
            } label: {
                Image(systemName: "xmark")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .padding(5)
                    .background(.thickMaterial, in: Circle())
                    .background(.black.opacity(0.5), in: Circle())
            }
            .buttonBorderShape(.roundedRectangle)
            .buttonStyle(.borderless)
            .hoverEffect(.lift)
            .padding(7.5)
            .keyboardShortcut(.cancelAction)
        }
        .onChange(of: isFavorited, perform: { favoriteStatus in
            bookmark.isFavorited = favoriteStatus
        })
        .task {
            await bookmark.cachedImage(saveTo: $cachedPreview)
        }
    }
    
    func backView() -> some View {
        VStack(spacing: 0) {
            HStack {
                Button("Cancel") {
                    editing.toggle()
                }
                .padding()
                Spacer()
                Button("Save") {
                    bookmark.title = title
                    bookmark.notes = notes
                    if moc.hasChanges {
                        try? moc.save()
                    }
                    editing.toggle()
                }
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .padding()
                
            }
            .buttonStyle(.borderless)
            .background(.thinMaterial)
            
            Form {
                Section("Title") {
                    TextField("Title", text: $title)
                }
                
                Section("Notes") {
                    TextEditor(text: $notes)
                        .placeholder("Notes", contents: notes)
                        .frame(height: 150)
                }
            }
        }
    }
    
    func thumbnail() -> some View {
        VStack {
            switch(cachedPreview?.previewState) {
            case .thumbnail:
                cachedPreview?.image!
                    .resizable()
                    .scaledToFit()
            case .icon:
                cachedPreview?.image!
                    .resizable()
                    .aspectRatio(1/1, contentMode: .fit)
                    .cornerRadius(20, style: .continuous)
                    .padding(15)
                    .frame(maxWidth: .infinity, maxHeight: 175)
                    .clipped()
            case .firstLetter:
                Color(uiColor: .systemGray2)
                    .aspectRatio(16/9, contentMode: .fit)
                    .overlay(
                        Group {
                            if let firstChar: Character = bookmark.wrappedTitle.first {
                                Text(String(firstChar))
                                    .font(.largeTitle.weight(.medium))
                                    .foregroundColor(.white)
                                    .scaleEffect(2)
                            }
                        }
                    )
            default:
                Rectangle()
                    .foregroundColor(.secondary.opacity(0.5))
                    .shimmering()
                    .aspectRatio(16/9, contentMode: .fit)
            }
        }
    }
    
    func actionButtons() -> some View {
        Group {
            if !hideFavoriteOption {
                Button {
                    isFavorited.toggle()
                    try? moc.save()
                } label: {
                    if isFavorited {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.pink)
                            .transition(.movingParts.pop(.pink))
                    } else {
                        Image(systemName: "heart")
                            .foregroundColor(.pink)
                    }
                }
                .keyboardShortcut("F", modifiers: [.shift, .command])
            }
            
            Button(action: openBookmark) {
                Image(systemName: "safari")
            }
            
            ShareButton(url: bookmark.wrappedURL) {
                Image(systemName: "square.and.arrow.up")
            }
            
            Button {
                editing.toggle()
            } label: {
                Image(systemName: "pencil")
            }
            
            Button(role: .destructive) {
                deleteConfirmation = true
            } label: {
                Image(systemName: "trash")
                    .confirmationDialog("Are you sure you want to delete this bookmark?", isPresented: $deleteConfirmation, titleVisibility: .visible) {
                        Button("Delete Bookmark", role: .destructive) {
                            showDetails.toggle()
                            BookmarksManager.shared.deleteBookmark(bookmark)
                            try? moc.save()
                        }
                    } message: {
                        Text("It will be deleted from all your iCloud devices.")
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


private struct AdaptiveScrollView<Content: View>: View {
    var notes: String
    
    @ViewBuilder var content: () -> Content
    var body: some View {
        Group {
            if notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                content()
            } else {
                if #available(iOS 16.0, *) {
                    ViewThatFits {
                        content()
                        
                        ScrollView {
                            content()
                        }
                    }
                } else {
                    ScrollView {
                        content()
                    }
                }
            }
        }
    }
}
