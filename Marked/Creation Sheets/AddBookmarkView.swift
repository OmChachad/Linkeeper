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
//import SPAlert

struct AddBookmarkView: View {
    @ObservedObject var bookmarks: Bookmarks
    @ObservedObject var folders: Folders
    var folderPreset: Folder?
    
    @Environment(\.scenePhase) var scenePhase
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
                        
                        ForEach(folders.items, id: \.self) { folder in
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
                        let bookmark = Bookmark(title: title, url: URL(string: url)!.sanitise, host: host, notes: notes, date: Date.now, folder: folder)
                        bookmarks.items.append(bookmark)
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
            AddFolderView(folders: folders)
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

// MARK: Unused, currently
//    var searchedFolders: [Folder] {
//        if searchText.isEmpty {
//            return folders.items
//        } else {
//            return folders.items.filter{ $0.title.localizedCaseInsensitiveContains(searchText) }
//        }
//    }
    
    func fetchTitleAndHost(url: URL) -> (String?, String?) { // not functioning, to be fixed
        let metadataProvider = LPMetadataProvider()
        var title: String?
        var host: String?
        
        metadataProvider.startFetchingMetadata(for: url) { (metadata, error) in
            guard error == nil else { return }
            DispatchQueue.main.async {
                let receivedMetadata = metadata
                if let URLTitle = receivedMetadata?.title {
                    title = URLTitle
                }
                if let URLHost = receivedMetadata?.url?.host {
                    host = URLHost
                }
            }
        }
        return (title, host)
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

struct AddBookmarkView_Previews: PreviewProvider {
    static var previews: some View {
        AddBookmarkView(bookmarks: Bookmarks(), folders: Folders())
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


struct FolderPickerItem: View {
    var folder: Folder
    
    var body: some View {
        HStack {
            Image(systemName: folder.symbol)
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)
                .foregroundColor(FolderColorOptions.values[folder.accentColor])
            Text(folder.title)
        }
    }
}

