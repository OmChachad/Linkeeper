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
    @Environment(\.keyboardShortcut) var keyboardShortcut
    
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
                    frontView()
                } back: {
                    backView()
                }
            }
            .frame(maxHeight: 400)
            .shadow(color: .black.opacity(0.25), radius: 10)
            .onAppear {
                title = bookmark.wrappedTitle
                notes = bookmark.wrappedNotes
            }

    }
    
    func frontView() -> some View {
        VStack(spacing: 0) {
            VStack {
                switch(detailViewImage?.previewState) {
                case .thumbnail:
                    detailViewImage?.image!
                        .resizable()
                        .scaledToFit()
                        .scaledToFill()
                case .icon:
                    detailViewImage?.image!
                        .resizable()
                        .aspectRatio(1/1, contentMode: .fit)
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                        .padding(15)
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
                        
                            .scaledToFill()
                    }
                    
                default:
                    Rectangle()
                        .shimmering()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: 175)
            .clipped()
            .background(Color(.systemGray6))
            .matchedGeometryEffect(id: "\(bookmark.wrappedUUID)-Image", in: namespace)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5)) {
                Button {
                    if bookmark.isFavorited { showRemovedFromFav = true } else { showAddedToFav = true }
                    bookmark.isFavorited.toggle()
                    try! moc.save()
                } label: {
                    Image(systemName: bookmark.isFavorited ? "heart.fill" : "heart")
                        .foregroundColor(.pink)
                }
                .keyboardShortcut("F", modifiers: [.shift, .command])
                
                Button() {
                    openURL(bookmark.wrappedURL)
                } label: {
                    Image(systemName: "safari")
                }
                
                if #available(iOS 16.0, *) {
                    ShareLink(item: bookmark.wrappedURL) {
                        Image(systemName: "square.and.arrow.up")
                    }
                } else {
                    Button {
                        share(url: bookmark.wrappedURL)
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
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
            }   .font(.title2)
                .padding(10)
                .background(Color(.systemGray4))
            
            AdaptiveScrollView(notes: bookmark.wrappedNotes) {
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
                }
                .padding(20)
            }
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        .matchedGeometryEffect(id: "\(bookmark.wrappedUUID)-Background", in: namespace)
        .overlay {
            Button {
                showDetails.toggle()
            } label: {
                Image(systemName: "xmark")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .padding(5)
                    .background(Circle().foregroundColor(Color(UIColor.systemGray3)))
            }
            .padding(7.5)
            .keyboardShortcut(.cancelAction)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
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
        Group {
            if flipped {
                back()
                    .background {
                        front()
                    }
            } else {
                front()
                    .background {
                        back()
                    }
            }
        }
        .frame(maxWidth: 500)
        //.frame(height: UIScreen.main.bounds.height / 2)
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
        withAnimation(Animation.linear(duration: 0.25)) {
            flashcardRotation += 90
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            flipped.toggle()
            contentRotation += 180
            withAnimation(Animation.linear(duration: 0.25)) {
                flashcardRotation += 90
            }
        }
    }
}

//
//struct CardFlipView<Front: View, Back: View>: View {
//    @Binding var isFlipped: Bool
//    @ViewBuilder var front: () -> Front
//    @ViewBuilder var back: () -> Back
//
//    @State private var frontRotation: Double = -90
//    @State private var backRotation: Double = 0
//
//    let flipDuration: CGFloat = 0.1
//
//    var body: some View {
////        ZStack {
////                front()
////                    .rotation3DEffect(Angle(degrees: frontRotation), axis: (x: 0, y: 1, z: 0))
//                    //.opacity(isFlipped ? 1 : 0)
//                back()
//                    .rotation3DEffect(Angle(degrees: backRotation), axis: (x: 0, y: 1, z: 0))
//                    //.opacity(isFlipped ? 0 : 1)
//       // }
//        .frame(height: UIScreen.main.bounds.height / 2)
//        .onChange(of: isFlipped) { _ in
//            flipCard()
//        }
//    }
//
//    func flipCard () {
//            //isFlipped = !isFlipped
//            if !isFlipped {
//                withAnimation(.linear(duration: flipDuration)) {
//                    backRotation = 90
//                }
//                withAnimation(.linear(duration: flipDuration).delay(flipDuration)){
//                    frontRotation = 0
//                }
//            } else {
//                withAnimation(.linear(duration: flipDuration)) {
//                    frontRotation = -90
//                }
//                withAnimation(.linear(duration: flipDuration).delay(flipDuration)){
//                    backRotation = 0
//                }
//            }
//        }
//}


struct AdaptiveScrollView<Content: View>: View {
    var notes: String
    
    @ViewBuilder var content: () -> Content
    var body: some View {
        Group {
            if notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                content()
            } else {
                ScrollView {
                    content()
                }
            }
        }
    }
}
