//
//  MoveBookmarksView.swift
//  Linkeeper
//
//  Created by Om Chachad on 15/05/23.
//

import SwiftUI
import CoreData

struct MoveBookmarksView: View {
    @Environment(\.managedObjectContext) var moc
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Folder.index, ascending: true)]) var folders: FetchedResults<Folder>
    @Environment(\.dismiss) var dismiss
    
    @State private var creatingFolder = false
    
    var toBeMoved: [Bookmark]
    var completion: () -> Void
    
    init(toBeMoved: [Bookmark], completion: @escaping () -> Void) {
        self.toBeMoved = toBeMoved
        self.completion = completion
        _selectedFolder = State(initialValue: toBeMoved.first?.folder)
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
                        Button {
                            creatingFolder.toggle()
                        } label: {
                            Image(systemName: "folder.badge.plus")
                        }
                        
                        Spacer()
                        
                        Button("Cancel", action: dismiss.callAsFunction)
                        
                        Button("**Move**") {
                            toBeMoved.forEach { bookmark in
                                bookmark.folder = selectedFolder
                            }
                            try? moc.save()
                            completion()
                            reloadAllWidgets()
                            //toBeMoved.removeAll()
                            dismiss()
                        }
                        .disabled(toBeMoved.first?.folder == selectedFolder)
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
                            Button {
                                creatingFolder.toggle()
                            } label: {
                                Image(systemName: "folder.badge.plus")
                            }
                            
                            Button("**Move**") {
                                toBeMoved.forEach { bookmark in
                                    bookmark.folder = selectedFolder
                                }
                                try? moc.save()
                                completion()
                                reloadAllWidgets()
                                //toBeMoved.removeAll()
                                dismiss()
                            }
                            .disabled(toBeMoved.first?.folder == selectedFolder)
                        }
                        
                        ToolbarItemGroup(placement: .cancellationAction) {
                            Button("Cancel", action: dismiss.callAsFunction)
                        }
                    }
            }
        #endif
        }
        .sheet(isPresented: $creatingFolder) {
            AddFolderView()
        }
        .animation(.default, value: selectedFolder)
    }
    
    var contents: some View {
        VStack {
            if selectedFolder != nil && selectedFolder != toBeMoved.first?.folder {
                Text("^[\(toBeMoved.count) Bookmark](inflect: true) will be moved to **\(selectedFolder!.wrappedTitle)**")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            } else if toBeMoved.first?.folder != selectedFolder && selectedFolder == nil {
                Text("^[\(toBeMoved.count) Bookmark](inflect: true) will be moved to **All Bookmarks**")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            } else {
                Spacer()
                    .frame(height: 30)
            }
            
            HStack {
                StackOfTwoIcons(bookmarks: [Bookmark](toBeMoved))
                Text("^[**\(toBeMoved.count) Bookmark**](inflect: true)")
            }
            .padding(10)
            .background {
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                #if os(iOS)
                    .foregroundColor(Color(UIColor.systemGray5))
                #else
                    .fill(.regularMaterial)
                #endif
            }
            
            Spacer()
                .frame(height: 20)
            
            FolderPickerView(selectedFolder: $selectedFolder)
        }
    }
}


struct IconView: View {
    let color: Color
    let icon: String
    
    let resizable: Bool
    
    init(color: Color, icon: String) {
        self.color = color
        self.icon = icon
        self.resizable = false
    }
    
    init(color: Color, icon: String, resizable: Bool) {
        self.color = color
        self.icon = icon
        self.resizable = resizable
    }
    
    var body: some View {
        if resizable {
            
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .gradientify(with: color)
                .overlay {
                    Image(systemName: icon)
                        .foregroundColor(.white)
                }
        } else {
            
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .gradientify(with: color)
                .frame(width: 35, height: 35)
                .overlay {
                    Image(systemName: icon)
                        .foregroundColor(.white)
                }
        }
    }
}

struct StackOfTwoIcons: View {
    var bookmarks: [Bookmark]
    
    var body: some View {
        Group {
            ZStack {
                if bookmarks.count > 1 {
                    IconView(color: .blue, icon: "paperclip")
                        .scaleEffect(0.8)
                        .offset(y: -7.5)
                        .shadow(radius: 5)
                }
                
                IconView(color: .blue, icon: "paperclip")
            }
        }
        .offset(y: bookmarks.count > 1 ? 1 : 0)
    }
}
