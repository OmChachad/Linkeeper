//
//  AddBookmarkView.swift
//  Marked
//
//  Created by Om Chachad on 27/04/22.
//

import SwiftUI
import LinkPresentation
import UIKit
import Shimmer

struct AddBookmarkView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) var moc
    @Environment(\.keyboardShortcut) var keyboardShortcut
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Folder.index, ascending: true)]) var folders: FetchedResults<Folder>
    
    var folderPreset: Folder?
    
    @ObservedObject var clipboard = Clipboard()
    
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
        return UIPasteboard.general.string
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
                        
                        Button {
                            self.url = pasteboardContents!
                        } label: {
                            Image(systemName: "doc.on.clipboard")
                                .padding(.leading, 10)
                        }
                        .buttonStyle(.borderless)
                        .disabled(pasteboardContents?.isValidURL == false || pasteboardContents == nil)
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
                    if url.isValidURL && title.isEmpty {
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
                        .disabled(!url.isValidURL || title.isEmpty)
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
        
        .SPAlert(
            isPresent: $showDonePopUp,
            title: "Added to Bookmarks",
            duration: 1.0,
            preset: .done,
            haptic: .success
        )
        
        .onChange(of: url) { newURL in
            title = ""
            if newURL.isValidURL {
                
                if let URLforTitle = URL(string: newURL)?.sanitise {
                    LPMetadataProvider().startFetchingMetadata(for: URLforTitle) { (metadata, error) in
                        guard error == nil else {
                            return
                        }
                        DispatchQueue.main.async {
                            let receivedMetadata = metadata
                            if let URLTitle = receivedMetadata?.title {
                                self.title = URLTitle
                                askForTitle = false
                            } else {
                                withAnimation {
                                    askForTitle = true
                                }
                            }
                            if let URLHost = receivedMetadata?.url?.host {
                                self.host = URLHost
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            folder = folderPreset
        }
    }
    
    class Clipboard: ObservableObject {
        func hasURLS() -> Bool {
            return UIPasteboard.general.hasURLs
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
