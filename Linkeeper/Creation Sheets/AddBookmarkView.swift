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
    var folderPreset: Folder?
    
    @Environment(\.managedObjectContext) var moc
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Folder.index, ascending: true)]) var folders: FetchedResults<Folder>
    
    @Environment(\.dismiss) var dismiss
    
    @State private var url = ""
    @State private var host = ""
    @State private var title = ""
    @State private var notes = ""
    @State private var folder: Folder?
    
    @State private var askForTitle = false
    
    @FocusState var isInputActive: Bool
    
    @State private var addingNewFolder = false
    
    @State private var showDonePopUp = false
    
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
                            self.url = UIPasteboard.general.string!
                        } label: {
                            Image(systemName: "doc.on.clipboard")
                                .padding(.leading, 10)
                        }
                        .buttonStyle(.borderless)
                        .disabled(!UIPasteboard.general.hasURLs)
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
                        Text("None")
                            .tag(nil as Folder?)
                        
                        ForEach(folders, id: \.self) { folder in
                            FolderPickerItem(folder: folder)
                                .tag(folder as Folder?)
                        }
                    }
                    
                    Button { addingNewFolder = true } label: {
                        Label("Create Folder", systemImage: "plus")
                    }
                }
                
                Section {
                    
                    ZStack(alignment: Alignment(horizontal: .center, vertical: .top)) {
                        TextEditor(text: $notes)
                            .focused($isInputActive)
                            .padding(EdgeInsets(top: -7, leading: -4, bottom: -7, trailing: -4))
                        if notes.isEmpty {
                            HStack {
                                Text("Add notes (optional)")
                                    .foregroundColor(Color(UIColor.placeholderText))
                                    .allowsHitTesting(false)
                                Spacer()
                            }
                        }
                    }
                    .frame(height: 150)
                    .padding(.top, 7)
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
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
                    .shimmering(active: url.isValidURL && title.isEmpty)
                    
                }
                
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    if url.isValidURL && title.isEmpty {
                        ProgressView()
                            .opacity(0.7)
                    }
                }
                
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                        .frame(maxWidth: isInputActive == true ? .infinity : 0, maxHeight: isInputActive == true ? .infinity : 0)
                    
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
}



struct AddBookmarkView_Previews: PreviewProvider {
    static var previews: some View {
        AddBookmarkView()
    }
}


extension URL { // This adds https to the URL if the URl doesn't have it already
    var sanitise: URL {
        if var components = URLComponents(url: self, resolvingAgainstBaseURL: false) {
            if components.scheme == nil {
                components.scheme = "https"
            }
            return components.url ?? self
        }
        return self
    }
}

extension String {
    var isValidURL: Bool {
        let detector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        if let match = detector.firstMatch(in: self, options: [], range: NSRange(location: 0, length: self.utf16.count)) {
            return match.range.length == self.utf16.count
        } else {
            return false
        }
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

