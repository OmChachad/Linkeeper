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
    
    var detailViewImage: DetailsPreview?
    
    @State private var deleteConfirmation = false
    
    @State private var showAddedToFav = false
    @State private var showRemovedFromFav = false
    
    var body: some View {
        VStack {
            Flashcard(editing: $editing) {
                VStack(spacing: 0) {
                    Group {
                        switch(detailViewImage?.previewState) {
                        case .thumbnail:
                            detailViewImage?.image!
                                .resizable()
                                .scaledToFit()
                        case .icon:
                            ZStack {
                                detailViewImage?.image!
                                    .resizable()
                                    .scaledToFit()
                                    .padding(20)
                            }
                        case .firstLetter:
                            if let firstChar: Character = bookmark.wrappedTitle.first {
                                Color(uiColor: .systemGray2)
                                    .aspectRatio(16/9, contentMode: .fit)
                                    .overlay(
                                        Text(String(firstChar))
                                            .font(.largeTitle.weight(.medium))
                                            .foregroundColor(.white)
                                            .scaleEffect(2)
                                    )
                            }
                        default:
                            Rectangle()
                                .shimmering()
                        }
                    }
                    .background(Color(.systemGray6))
                    .matchedGeometryEffect(id: "\(bookmark.wrappedUUID)-Image", in: namespace)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5)) {
                        Button() {
                            if bookmark.isFavorited { showRemovedFromFav = true } else { showAddedToFav = true }
                            bookmark.isFavorited.toggle()
                            try! moc.save()
                        } label: {
                            Image(systemName: bookmark.isFavorited ? "heart.fill" : "heart")
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
                                        moc.delete(bookmark)
                                        try? moc.save()
                                    }
                                } message: {
                                    Text("It will be deleted from all your iCloud devices.")
                                }
                        }
                        .SPAlert(isPresent: $showAddedToFav, title: "Added to Favorites!", duration: 1, dismissOnTap: true, preset: .custom(UIImage(systemName: "heart.fill")!), haptic: .success)
                        .SPAlert(isPresent: $showRemovedFromFav, title: "Removed from Favorites!", duration: 1, dismissOnTap: true, preset: .custom(UIImage(systemName: "heart.slash.fill")!), haptic: .success)
                    } .font(.title2)
                        .padding(10)
                        .background(Color(.systemGray4))
                    
                    VStack(alignment: .leading, spacing: 0) {
                        Text(bookmark.wrappedTitle)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .matchedGeometryEffect(id: "\(bookmark.wrappedUUID)-Title", in: namespace)
                        Text(bookmark.wrappedHost)
                            .frame(maxWidth: .infinity, alignment: .leading)
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
                    } .padding(20)
                }
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                .matchedGeometryEffect(id: "\(bookmark.wrappedUUID)-Background", in: namespace)
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
                .onAppear {
                    title = bookmark.wrappedTitle
                    notes = bookmark.wrappedNotes
                }
                .frame(height: 382.5)
                .frame(maxWidth: 500)
            }
        }

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
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
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
