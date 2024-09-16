//
//  FolderPickerView.swift
//  Linkeeper
//
//  Created by Om Chachad on 11/07/24.
//

import SwiftUI

struct FolderPickerView: View {
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Folder.index, ascending: true)], predicate: NSPredicate(format: "parentFolder == nil")) var parentFolders: FetchedResults<Folder>
    @Binding var selectedFolder: Folder?
    
    var body: some View {
        List {
            Section("Folders") {
                FolderButton(for: nil) // "None" Button
                
                Button("") { }
                .buttonStyle(.borderless)
                #if os(macOS)
                .padding(.vertical, 5)
                #endif
                .allowsHitTesting(false)
                .accessibilityHidden(true)
                
                OutlineGroup([Folder](parentFolders), id: \.self, children: \.childFoldersArray) { folder in
                    FolderButton(for: folder)
                }
            }
        }
        #if !os(visionOS)
        .listStyle(.plain)
        #endif
    }
    
    func FolderButton(for folder: Folder?) -> some View {
        Button {
            self.selectedFolder = folder
        } label: {
            HStack {
                Label {
                    Text(folder?.wrappedTitle ?? "None")
                        .lineLimit(1)
                        .foregroundColor(.primary)
                } icon: {
                    Image(systemName: folder?.wrappedSymbol ?? "xmark.circle")
                        .foregroundColor(folder?.wrappedColor ?? .secondary)
                }
                
                if selectedFolder == folder && !isMac {
                    Image(systemName: "checkmark")
                        .foregroundColor(.accentColor)
                }
                
                Spacer()
            }
            #if os(macOS)
            .padding(.vertical, 5)
            #endif
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.borderless)
        #if os(macOS)
        .listRowBackground(
            Color.secondary.opacity(selectedFolder == folder ? 0.5 : 0.0)
        )
        #endif
    }
}
