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
//    init(toBeMoved: [Bookmark]) {
//        self.toBeMoved = toBeMoved
//    }
    
    @State private var selectedFolder: Folder? = nil
    
    var body: some View {
        NavigationView {
            VStack {
                if selectedFolder != nil && selectedFolder != toBeMoved.first?.folder {
                    Text("^[\(toBeMoved.count) Bookmark](inflect: true) will be moved to **\(selectedFolder!.wrappedTitle)**")
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                } else if toBeMoved.first?.folder != selectedFolder && selectedFolder == nil {
                    Text("^[\(toBeMoved.count) Bookmark](inflect: true) will be removed from any Folder, and will only be accessible from the **All** section.")
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
                        .foregroundColor(Color(UIColor.systemGray5))
                }
                
                Spacer()
                    .frame(height: 20)
                
                List {
                    Section("No Folder") {
                        Button {
                            selectedFolder = nil
                        } label: {
                            Label {
                                Text("No Folder")
                            } icon: {
                                Image(systemName: "xmark.circle")
                                    .font(.headline)
                            }
                        }
                        .listRowBackground(
                            Color.secondary.opacity(selectedFolder == nil ? 0.5 : 0.0)
                        )
                    }
                    
                    Section("Existing Folders") {
                        ForEach(folders, id: \.self) { folder in
                            Button {
                                self.selectedFolder = folder
                            } label: {
                                Label {
                                    Text(folder.wrappedTitle)
                                } icon: {
                                    Image(systemName: folder.wrappedSymbol)
                                        .foregroundColor(folder.wrappedColor)
                                }
                            }
                            
                            .listRowBackground(
                                Color.secondary.opacity(selectedFolder == folder ? 0.5 : 0.0)
                            )
                        }
                    }
                }
                .listStyle(.plain)
            }
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
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
                        //toBeMoved.removeAll()
                        dismiss()
                    }
                    .disabled(toBeMoved.first?.folder == selectedFolder)
                }
                
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                selectedFolder = toBeMoved.first?.folder
                try? moc.save()
            }
            .sheet(isPresented: $creatingFolder) {
                AddFolderView()
            }
            .animation(.default, value: selectedFolder)
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




