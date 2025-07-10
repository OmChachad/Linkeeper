//
//  FolderGridItem.swift
//  Linkeeper
//
//  Created by Om Chachad on 12/06/24.
//

import SwiftUI

struct FolderGridItem: View {
    @Environment(\.managedObjectContext) var moc
    @Environment(\.colorScheme) var colorScheme
    
    @ObservedObject var folder: Folder
    var namespace: Namespace.ID
    var isEditing: Bool
    
    @State private var isTargeted = false

    @AppStorage("ShadowsEnabled") var shadowsEnabled = true
    
    var body: some View {
        NavigationLink {
            BookmarksView(folder: folder)
        } label: {
            HStack {
                Image(systemName: folder.wrappedSymbol)
                    .imageScale(.large)
                    .frame(width: 30)
                    .matchedGeometryEffect(id: "\(folder.wrappedUUID)-Icon", in: namespace)
                
                Text(folder.wrappedTitle)
                    .bold()
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .matchedGeometryEffect(id: "\(folder.wrappedUUID)-Title", in: namespace)
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .frame(height: 50)
            .padding(.horizontal, 5)
            .padding(10)
            .foregroundColor(.primary.opacity(isMac ? 1 : 0.6))
            .background(folder.wrappedColor.opacity(0.5).gradientify(colorScheme: colorScheme))
            .background(.ultraThinMaterial)
            .cornerRadius(15, style: .continuous)
            #if !os(macOS)
            .contentShape(.hoverEffect, .rect(cornerRadius: 15))
            #endif
//            .background {
//                RoundedRectangle(cornerRadius: 15, style: .continuous)
//                    .stroke(LinearGradient(colors: [folder.wrappedColor.opacity(0.2), .black.opacity(0)], startPoint: .topLeading, endPoint: .bottomLeading), lineWidth: 4)
//            }
            .matchedGeometryEffect(id: "\(folder.wrappedUUID)-Background", in: namespace)
            #if !os(macOS)
            .hoverEffect(.lift)
            #endif
            .frame(maxWidth: .infinity, maxHeight: 60, alignment: .center)
            .opacity(isTargeted ? 0.2 : 1)
            .shadow(color: .black.opacity(0.2), radius: shadowsEnabled ? 2 : 0) // Checks if the shadows are enabled in Settings, otherwise only shows them when the bookmark is not selected.
            .padding(.vertical, 2.5)
        }
        .buttonStyle(.plain)
        .folderActions(folder: folder, isEditing: isEditing)
        .dropDestination(isTargeted: $isTargeted) { bookmark, url in
            addDroppedBookmarkToFolder(bookmark: bookmark, url: url, folder: folder)
        }
    }
    
    func addDroppedBookmarkToFolder(bookmark: Bookmark?, url: URL, folder: Folder) {
        if let bookmark {
            bookmark.folder = folder
            try? moc.save()
        } else {
            BookmarksManager.shared.addDroppedURL(url, to: folder)
        }
    }
}
