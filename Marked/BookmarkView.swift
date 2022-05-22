//
//  BookmarkView.swift
//  Marked
//
//  Created by Om Chachad on 11/05/22.
//

import SwiftUI
import LinkPresentation

struct BookmarkView: View {
    @StateObject var LinkPresentationModel: LinkViewModel
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
                    .aspectRatio(4/3, contentMode: .fill)
                    .clipped()
                    .frame(minWidth: 130, idealWidth: 165, maxWidth: 165)
                
                
                if let image: Image = image {
                    if preview == .thumbnail {
                        image
                            .resizable()
                            .aspectRatio(4/3, contentMode: .fill)
                            .clipped()
                            .frame(minWidth: 130, idealWidth: 165, maxWidth: 165)
                    } else if preview == .icon {
                        ZStack {
                            Rectangle()
                                .aspectRatio(4/3, contentMode: .fill)
                                .foregroundColor(.white)
                                .frame(minWidth: 130, idealWidth: 165, maxWidth: 165)
                            
                            image
                                .resizable()
                                .aspectRatio(1/1, contentMode: .fit)
                                .padding(20)
                                .background(Color(red: 0.8980392157, green: 0.8980392157, blue: 0.9137254902))
                                .cornerRadius(20)
                                .clipped()
                                .scaleEffect(0.75)
                            
                        }
                    }
                    
                } else if preview == .firstLetter {
                    if let firstChar: Character = bookmark.title.first {
                        Color(uiColor: .systemGray2)
                            .aspectRatio(4/3, contentMode: .fill)
                            .frame(minWidth: 130, idealWidth: 165, maxWidth: 165)
                            .overlay(
                                Text(String(firstChar))
                                    .font(.largeTitle.weight(.medium))
                                    .foregroundColor(.white)
                                    .scaleEffect(2)
                            )
                    }
                }
            }
            VStack {
                Text(bookmark.title)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
                Text(bookmark.host)
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
            openURL(bookmark.url)
        }
        .background(Color(UIColor.systemGray5))
        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        .task {
            do {
                let metadata = try await startFetchingMetadata(for: bookmark.url)
                
                
                
                if let imageProvider = metadata.imageProvider {
                    imageProvider.loadObject(ofClass: UIImage.self) { (image, error) in
                        guard error == nil else { return }
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
                        guard error == nil else { return }
                        if let image = iconImage as? UIImage {
                            DispatchQueue.main.async {
                                self.image = Image(uiImage: image)
                                preview = .icon
                                isShimmering = false
                            }
                        }
                    }
                } else {
                    preview = .firstLetter
                    isShimmering = false
                }
            } catch {
                print("Failed to load data")
            }
        }
        .onAppear {
            print("Test")
        }
        .animation(.default, value: isShimmering)
    }
    
    func startFetchingMetadata(for URL: URL) async throws -> LPLinkMetadata {
        try! await LPMetadataProvider().startFetchingMetadata(for: URL)
    }
}


struct BookmarkView_Previews: PreviewProvider {
    static var previews: some View {
        BookmarkView(LinkPresentationModel: LinkViewModel(url: URL(string: "https://www.hackingwithswift.com/quick-start/swiftui/how-to-convert-a-swiftui-view-to-an-image")!), bookmark: Bookmark(title: "iTech Everything", url: URL(string: "https://youtube.com/TheiTE")!, host: "youtube.com", notes: "My YouTube channel", date: Date.now))
    }
}
