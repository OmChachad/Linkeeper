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
    
    @State private var animatedShow = false
    
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
            #if os(visionOS)
            Flashcard(editing: $editing) {
                frontVisionView()
            } back: {
                backVisionView()
                    .frame(maxHeight: 400)
            }
            .opacity(animatedShow ? 1 : 0)
            .transition(.movingParts.blur)
            .animation(.easeInOut, value: animatedShow)
            #else
            Flashcard(editing: $editing) {
                frontView()
                    .cornerRadius(20, style: .continuous)
            } back: {
                backView()
                    .frame(maxHeight: 400)
                    .cornerRadius(20, style: .continuous)
            }
            .shadow(color: .black.opacity(0.25), radius: 10)
            #endif
        }
        .onChange(of: isFavorited) { favoriteStatus in
            bookmark.isFavorited = favoriteStatus
        }
        .onChange(of: bookmark) { newValue in
            newValue.cachedImage(saveTo: $cachedPreview)
        }
        .onChange(of: animatedShow) { newValue in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                showDetails = newValue
            }
        }
        .task {
            bookmark.cachedImage(saveTo: $cachedPreview)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                animatedShow = true
            }
        }
    }
    
    #if os(visionOS)
    func frontVisionView() -> some View {
        VStack {
            VStack(spacing: 0) {
                thumbnail()
                    .frame(maxWidth: .infinity)
                    .background(.regularMaterial)
                
                
                VStack(alignment: .leading, content: {
                    Text(bookmark.wrappedTitle)
                    Text(bookmark.wrappedHost)
                        .foregroundStyle(.secondary)
                })
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }
            .glassBackgroundEffect(in: RoundedRectangle(cornerRadius: 25, style: .continuous))
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: hideFavoriteOption ? 4 : 5)) {
                actionButtons()
                    .padding(7.5)
                    .hoverEffect(.highlight)
            }
            .font(.title2)
            .glassBackgroundEffect(in: Capsule())
        }
        .frame(width: 400)
        .overlay(alignment: .topTrailing) {
            Button {
                animatedShow = false
            } label: {
                Image(systemName: "xmark")
                    .imageScale(.large)
            }
            .contentShape(Circle())
            .hoverEffect(.highlight)
            .background(.ultraThinMaterial)
            .glassBackgroundEffect(in: Circle())
            .padding(.top, 10)
        }
    }
    
    func backVisionView() -> some View {
        VStack {
            VStack {
                TextField("Title", text: $title)
                    .textFieldStyle(.roundedBorder)
                
                TextField("Notes", text: $notes)
                    .textFieldStyle(.roundedBorder)
            }
            .padding()
            .glassBackgroundEffect(in: RoundedRectangle(cornerRadius: 25))
            
            HStack {
                Button("Cancel") {
                    editing.toggle()
                }
                .padding()

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
            .glassBackgroundEffect(in: Capsule())
        }
    }
    #endif
    
    func frontView() -> some View {
        VStack(spacing: 0) {
            thumbnail()
                .matchedGeometryEffect(id: "\(bookmark.wrappedUUID)-Image", in: namespace)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: hideFavoriteOption ? 4 : 5)) {
                actionButtons()
                    .padding(7.5)
                #if !os(macOS)
                    .hoverEffect(.highlight)
                #endif
            }
            .font(.title2)
            .padding(2.5)
            .background(.thickMaterial)
            .background(Color("DetailsEditBarColor").opacity(0.2))
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
                    .font(isVisionOS ? .title : .headline)
                    .foregroundColor(.secondary)
                    .padding(isVisionOS ? 10 : 5)
                    .background(.thickMaterial, in: Circle())
                    .background(.black.opacity(0.5), in: Circle())
                    #if os(visionOS)
                    .glassBackgroundEffect(in: Circle())
                    #endif
            }
            .keyboardShortcut(.cancelAction)
            .buttonStyle(.borderless)
            #if !os(macOS)
            .hoverEffect(.lift)
            .contentShape(.hoverEffect, .circle)
            #endif
            .padding(7.5)
        }
    }
    
    func backView() -> some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    editing.toggle()
                } label: {
                    Text("Cancel")
                        .padding()
                }
                
                
                Spacer()
                
                Button {
                    bookmark.title = title
                    bookmark.notes = notes
                    if moc.hasChanges {
                        try? moc.save()
                    }
                    editing.toggle()
                } label: {
                    Text("Save")
                        .padding()
                }
                //.tint(!title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .accentColor : nil)
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                
                .contentShape(Rectangle())
                
            }
            .tint(.accentColor)
            .buttonStyle(.borderless)
            .background(.thinMaterial)
            
            #if os(macOS)
            VStack(alignment: .leading) {
                Section("**Title**") {
                    TextField("Title", text: $title)
                        .textFieldStyle(.roundedBorder)
                }
                
                Section("**Notes**") {
                    TextEditor(text: $notes)
                        .background(.gray.opacity(0.2))
                        .cornerRadius(7.5, style: .continuous)
                        .labelsHidden()
                        .frame(height: 150)
                }
            }
            .padding()
            .background(.thickMaterial)
            .scrollContentBackground(visibility: .hidden)
            #else
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
            #endif
        }
        #if os(macOS)
        .cornerRadius(20, style: .continuous)
        #endif
    }
    
    func thumbnail() -> some View {
        VStack {
            switch(cachedPreview?.previewState) {
            case .thumbnail:
                cachedPreview?.image?
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
                Group {
                #if os(macOS)
                    Color(red: 174/255, green: 174/255, blue: 178/255)
                    #else
                    Color(uiColor: .systemGray2)
                #endif
                }
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
                    .foregroundColor(.red)
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
        .tint(.accentColor)
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
                if #available(iOS 16.0, macOS 13.0, *) {
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
