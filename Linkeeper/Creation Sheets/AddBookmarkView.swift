//
//  AddBookmarkView.swift
//  Marked
//
//  Created by Om Chachad on 27/04/22.
//

import SwiftUI
import LinkPresentation
import Shimmer

struct AddBookmarkView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) var moc
    @Environment(\.keyboardShortcut) var keyboardShortcut
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Folder.index, ascending: true)]) var folders: FetchedResults<Folder>
    
    var folderPreset: Folder?
    
    @State private var url = ""
    @State private var host = ""
    @State private var title = ""
    @State private var notes = ""
    @State private var folder: Folder?
    
    @State private var askForTitle = false
    
    @FocusState var isInputActive: Bool
    
    @State private var addingNewFolder = false
    @State private var showDonePopUp = false
    
    var pasteboardContents: String? {
        if !isMacCatalyst, #available(iOS 16.0, *) {
            return ""
        } else {
            return UIPasteboard.general.string
        }
    }
    
    var isMacCatalyst: Bool {
        #if targetEnvironment(macCatalyst)
            return true
        #else
            return false
        #endif
    }
    
    var isValidURL: Bool {
        if let url = URL(string: url)?.sanitise, url.absoluteString.isValidURL {
            return true
        } else {
            return false
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    HStack {
                        TextField("URL", text: $url)
                            .keyboardType(.URL)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .submitLabel(.done)
                        
                        Divider()
                        
                        if !isMacCatalyst, #available(iOS 16.0, *) {
                            PasteButton(payloadType: URL.self) { content in
                                if let url = content.first {
                                    self.url = url.absoluteString
                                }
                            }
                            .labelStyle(.iconOnly)
                            .buttonBorderShape(.capsule)
                            .offset(x: 5)
                        } else {
                            Button {
                                self.url = pasteboardContents!
                            } label: {
                                Image(systemName: "doc.on.clipboard")
                                    .padding(.leading, 10)
                            }
                            .buttonStyle(.borderless)
                            .disabled(pasteboardContents?.isValidURL == false || pasteboardContents == nil)
                            .padding(.trailing, 5)
                        }
                    }
                }
                
                
                if askForTitle {
                    Section(footer: Text("The URL you entered does not have a title by itself, you will have to type your own")) {
                        TextField("Title", text: $title)
                            .autocapitalization(.none)
                            .submitLabel(.done)
                    }
                }
                
                Section(footer: Text("Selecting \"None\" will cause this bookmark to only appear in the All Bookmarks section of the app")) {
                    Picker("Folder", selection: $folder) {
                        Text("None").tag(nil as Folder?)
                        
                        ForEach(folders, id: \.self) { folder in
                            FolderPickerItem(folder: folder)
                                .tag(folder as Folder?)
                        }
                    }

                    Button {
                        addingNewFolder.toggle()
                    } label: {
                        Text("Create New Folder")
                    }
                }
                
                Section {
                        TextEditor(text: $notes)
                            .placeholder("Add notes (optional)", contents: notes)
                            .focused($isInputActive)
                            .frame(height: 150)
                }
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    if let url = URL(string: url)?.sanitise, url.absoluteString.isValidURL, title.isEmpty {
                        ProgressView()
                            .opacity(0.7)
                    } else {
                        Button("Add") {
                            let sanitisedURL = URL(string: url)?.sanitise
                            let bookmark = Bookmark(context: moc)
                            bookmark.id = UUID()
                            bookmark.title = title
                            bookmark.date = Date.now
                            bookmark.host = host
                            bookmark.notes = notes
                            bookmark.url = sanitisedURL?.absoluteString
                            bookmark.folder = folder
                            
                            try? moc.save()
                            
                            dismiss()
                            showDonePopUp = true
                        }
                        .disabled(!isValidURL || title.isEmpty)
                        .keyboardShortcut("s", modifiers: .command)
                        .shimmering(active: url.isValidURL && title.isEmpty)
                    }
                    
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .keyboardShortcut(.cancelAction)
                }

                ToolbarItem(placement: .keyboard) {
                    Spacer()
                    
                    Button(isInputActive == true ? "Done" : "") {
                        isInputActive = false
                    } .allowsHitTesting(isInputActive)
                }
            }
            .navigationBarTitle(title.isEmpty ? "New Bookmark" : title)
        }
        
        .sheet(isPresented: $addingNewFolder) {
            AddFolderView()
        }
        // Alert for "Added New Bookmark" to be added later down the line
        .onChange(of: url) { newURL in
            askForTitle = false
            title = ""
            
            if let url = URL(string: newURL)?.sanitise, url.absoluteString.isValidURL {
                Task {
                    if let metadata = try await startFetchingMetadata(for: url, fetchSubresources: false, timeout: 10) {
                        DispatchQueue.main.async {
                            if let URLTitle = metadata.title {
                                if title.isEmpty {
                                    self.title = URLTitle
                                    askForTitle = false
                                }
                            } else {
                                askForTitle = true
                            }
                            if #available(iOS 16.0, *) {
                                if let URLHost = url.host {
                                    self.host = URLHost
                                }
                            } else {
                                if let URLHost = metadata.url?.host ?? metadata.originalURL?.host {
                                    self.host = URLHost
                                } else {
                                    self.host = url.absoluteString
                                }
                            }
                        }
                    } else {
                        return
                    }
                    
                    if title.isEmpty {
                        askForTitle = true
                    }
                }
            }
        }
        .animation(.default, value: askForTitle)
        .onAppear {
            folder = folderPreset
        }
    }
}



struct AddBookmarkView_Previews: PreviewProvider {
    static var previews: some View {
        AddBookmarkView()
    }
}






struct FolderPickerItem: View {
    var folder: Folder
    
    var body: some View {
        HStack {
            Image(systemName: folder.wrappedSymbol)
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)
                .foregroundColor(folder.wrappedColor)
            Text(folder.wrappedTitle)
        }
    }
}


// Doesn't work, gotta think about the fix
//func newBookmark(title: String, url: URL, host: String, notes: String, folder: Folder?) {
//    @Environment(\.managedObjectContext) var moc
//
//    let bookmark = Bookmark(context: moc)
//    bookmark.id = UUID()
//    bookmark.title = title
//    bookmark.date = Date.now
//    bookmark.host = host
//    bookmark.notes = notes
//    bookmark.url = url.absoluteString
//    bookmark.folder = folder
//
//    try? moc.save()
//}
