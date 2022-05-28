//
//  BookmarkDetails.swift
//  Linkeeper
//
//  Created by Om Chachad on 27/05/22.
//

import SwiftUI
import LinkPresentation
import Shimmer

struct BookmarkDetails: View {
    @Environment(\.managedObjectContext) var moc
    @Environment(\.openURL) var openURL
    @ObservedObject var cache = CacheModel()
    
    var bookmark: Bookmark
    var namespace: Namespace.ID
    @Binding var showDetails: Bool
    
    @State private var title = ""
    @State private var notes = ""
    @State private var editing = false
    
    @State private var isShimmering = true
    @State private var image: Image?
    @State private var preview = PreviewType.loading
    
    var body: some View {
        VStack {
            Flashcard(editing: $editing) {
                VStack(spacing: 0) {
                    Group {
                        if preview == .loading {
                            Rectangle()
                                .shimmering()
                        } else if preview == .thumbnail {
                            image!
                                .resizable()
                                .scaledToFit()
                            
                        } else if preview == .icon {
                            ZStack {
                                image!
                                    .resizable()
                                    //.aspectRatio(1/1, contentMode: .fit)
                                    .padding(20)
                            }
                        } else if preview == .firstLetter {
                            if let firstChar: Character = bookmark.wrappedTitle.first {
                                Color(uiColor: .systemGray2)
                                    .overlay(
                                        Text(String(firstChar))
                                            .font(.largeTitle.weight(.medium))
                                            .foregroundColor(.white)
                                            .scaleEffect(2)
                                    )
                            }
                        }
                    }
                    .background(Color(.systemGray6))
                    .matchedGeometryEffect(id: "\(bookmark.id!.uuidString)-Image", in: namespace)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5)) {
                        Button() {
                            
                        } label: {
                            Image(systemName: "heart.fill")
                                .foregroundColor(.pink)
                        }
                        
                        Button() {
                            openURL(bookmark.wrappedURL)
                        } label: {
                            Image(systemName: "safari")
                        }
                        
                        Button() {
                            
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                        }
                        
                        Button() {
                            editing.toggle()
                        } label: {
                            Image(systemName: "pencil")
                        }
                        
                        Button(role: .destructive) {
                            
                        } label: {
                            Image(systemName: "trash")
                        }
                    } .font(.title2)
                        .padding(10)
                        .background(Color(.systemGray4))
                    
                    VStack(alignment: .leading, spacing: 0) {
                        Text(bookmark.wrappedTitle)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .matchedGeometryEffect(id: "\(bookmark.id!.uuidString)-Title", in: namespace)
                        Text(bookmark.wrappedHost)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .font(.callout)
                            .foregroundColor(.secondary)
                            .matchedGeometryEffect(id: "\(bookmark.id!.uuidString)-Host", in: namespace)
                        
                        if !bookmark.wrappedNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            
                            Spacer()
                                .frame(height: 20)
                            
                            Text("NOTES")
                                .foregroundColor(.secondary)
                                .font(.headline)
                            Text(bookmark.wrappedNotes)
                        }
                    } .padding(20)
                }
               // .background(Color(UIColor.systemGray5))
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                .matchedGeometryEffect(id: "\(bookmark.id!.uuidString)-Background", in: namespace)
                .overlay {
                    VStack {
                        HStack {
                            Spacer()
                            Button {
                                showDetails.toggle()
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                    .padding(5)
                                    .background(Circle().foregroundColor(Color(UIColor.systemGray3)))
                            } .padding(7.5)
                            
                        }
                        Spacer()
                    }
                }
            } back: {
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
                .frame(height: 382.5)
                .frame(maxWidth: 500)
            }
        }
        .task {
            title = bookmark.wrappedTitle
            notes = bookmark.wrappedNotes
            
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
                                showPlaceHolder()
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
                                showPlaceHolder()
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
    }
    func showPlaceHolder() {
        preview = .firstLetter
        isShimmering = false
    }
    
    func startFetchingMetadata(for URL: URL) async throws -> LPLinkMetadata {
        let metadataProvider = LPMetadataProvider()
        return try! await metadataProvider.startFetchingMetadata(for: URL)
    }
}


struct Flashcard<Front, Back>: View where Front: View, Back: View {
    var front: () -> Front
    var back: () -> Back
    
    @State var flipped = false
    @Binding var editing: Bool
    
    @State var flashcardRotation = 0
    @State var contentRotation = 0
    
    init(editing: Binding<Bool>, @ViewBuilder front: @escaping () -> Front, @ViewBuilder back: @escaping () -> Back) {
        self.front = front
        self.back = back
        self._editing = editing
    }
    
    var body: some View {
        ZStack {
            if flipped {
                back()
            } else {
                front()
                    .glow()
            }
        }
        .frame(maxWidth: 500)
        .rotation3DEffect(.degrees(Double(contentRotation)), axis: (x: 0, y: 1, z: 0))
        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        .padding()
        .rotation3DEffect(.degrees(Double(flashcardRotation)), axis: (x: 0, y: 1, z: 0))
        
        .onChange(of: editing) { newValue in
            flipFlashcard()
        }
    }
    
    func flipFlashcard() {
        let animationTime = 0.5
        withAnimation(Animation.linear(duration: animationTime)) {
            flashcardRotation += 180
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            contentRotation += 180
            flipped.toggle()
        }
    }
}
