//
//  MoveFolderView.swift
//  Linkeeper
//
//  Created by Om Chachad on 1/23/25.
//

import SwiftUI

struct MoveFolderView: View {
    @Environment(\.managedObjectContext) var moc
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Folder.index, ascending: true)]) var folders: FetchedResults<Folder>
    @Environment(\.dismiss) var dismiss
    
    var folder: Folder
    
    var completion: () -> Void
    
    init(folder: Folder, completion: @escaping () -> Void) {
        self.folder = folder
        self.completion = completion
        _selectedFolder = State(initialValue: folder.parentFolder)
    }
    
    @State private var selectedFolder: Folder? = nil
    
    var parentFolders: [Folder] {
        folders.filter { $0.parentFolder == nil }
    }
    
    var body: some View {
        Group {
            #if os(macOS)
            contents
                .padding(.top)
                .safeAreaInset(edge: .bottom) {
                    HStack {
                        Spacer()
                        
                        Button("Cancel", action: dismiss.callAsFunction)
                        
                        Button("**Move**") {
                            folder.parentFolder = selectedFolder
                            folder.isPinned = false
                            
                            try? moc.save()
                            completion()
                            reloadAllWidgets()
                            dismiss()
                        }
                        .disabled(folder.parentFolder == selectedFolder)
                    }
                    .padding()
                    .background(.regularMaterial)
                }
                .frame(minWidth: 500, minHeight: 500)
            #else
            NavigationView {
                contents
                    .toolbar {
                        ToolbarItemGroup(placement: .confirmationAction) {
                            Button("**Move**") {
                                folder.parentFolder = selectedFolder
                                folder.isPinned = false
                                
                                try? moc.save()
                                completion()
                                reloadAllWidgets()
                                //toBeMoved.removeAll()
                                dismiss()
                            }
                            .disabled(folder.parentFolder == selectedFolder)
                        }
                        
                        ToolbarItemGroup(placement: .cancellationAction) {
                            Button("Cancel", action: dismiss.callAsFunction)
                        }
                    }
            }
        #endif
        }
        .animation(.default, value: selectedFolder)
    }
    
    var contents: some View {
        VStack {
            if selectedFolder != nil && selectedFolder != folder.parentFolder {
                Text("\(folder.wrappedTitle) will be moved to **\(selectedFolder!.wrappedTitle)**")
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            } else if folder.parentFolder != selectedFolder && selectedFolder == nil {
                Text("\(folder.wrappedTitle) will be moved to **All Bookmarks**")
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            } else {
                Spacer()
                    .frame(height: 30)
            }
            
            HStack {
                IconView(color: folder.wrappedColor, icon: folder.wrappedSymbol)
                Text(folder.wrappedTitle)
                    .bold()
                    .foregroundColor(.primary)
            }
            .padding(10)
            .background {
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                #if os(iOS)
                    .foregroundColor(Color(UIColor.systemGray5))
                #else
                    .fill(.thickMaterial)
                #endif
            }
            
            Spacer()
                .frame(height: 20)
            
            FolderPickerView(selectedFolder: $selectedFolder, type: .moveFolder(excluding: folder))
        }
    }
}
