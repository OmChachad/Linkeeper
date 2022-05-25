//
//  BookmarkView.swift
//  Marked
//
//  Created by Om Chachad on 11/05/22.
//

import SwiftUI
import LinkPresentation

struct BookmarkView: View {
    @Environment(\.managedObjectContext) var moc
    @Environment(\.openURL) var openURL
    
    var bookmark: Bookmark
    
    @State private var isShimmering = true
    
    @State private var image: Image?
    
    @State private var preview = PreviewType.loading
    
    enum PreviewType {
        case loading
        case thumbnail
        case icon
        case firstLetter
    }
    
    var body: some View {
        VStack {
            
            ZStack {
                Rectangle()
                    .foregroundColor(.secondary.opacity(isShimmering ? 0.5 : 0.2))
                    .shimmering(active: isShimmering)
                    .clipped()
                
                Group {
                    if preview != .loading {
                        if preview == .thumbnail {
                            image!
                                .resizable()
                                .clipped()
                        } else if preview == .icon {
                            ZStack {
                                Rectangle()
                                    .foregroundColor(.white)
                                
                                image!
                                    .resizable()
                                    .aspectRatio(1/1, contentMode: .fit)
                                    .padding(20)
                                    .background(Color(red: 0.8980392157, green: 0.8980392157, blue: 0.9137254902))
                                    .cornerRadius(20)
                                    .clipped()
                                    .scaleEffect(0.75)
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
                }
                
            }
            .aspectRatio(4/3, contentMode: .fill)
            .frame(minWidth: 130, idealWidth: 165, maxWidth: 165)
            VStack {
                Text(bookmark.wrappedTitle)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
                Text(bookmark.wrappedHost)
                    .lineLimit(1)
                    .font(.callout)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 10)
            .offset(y: -5)
            .padding(5)
        }
        .onTapGesture {
            openURL(bookmark.wrappedURL)
        }
        .background(Color(UIColor.systemGray5))
        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        .task {
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
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
                if preview == .loading {
                    showPlaceHolder()
                }
            }
        }
        .animation(.default, value: isShimmering)
    }
//    func indexOf(bookmark: Bookmark?) -> Int? {
//        if let index = bookmarks.items.firstIndex(of: bookmark!) {
//            return index
//        } else {
//            return nil
//        }
//    }
    
    func showPlaceHolder() {
        preview = .firstLetter
        isShimmering = false
    }
    
    func startFetchingMetadata(for URL: URL) async throws -> LPLinkMetadata {
        let metadataProvider = LPMetadataProvider()
        return try! await metadataProvider.startFetchingMetadata(for: URL)
    }
}


