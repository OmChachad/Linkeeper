//
//  AddBookmarkView.swift
//  Marked
//
//  Created by Om Chachad on 27/04/22.
//

import SwiftUI
import LinkPresentation

struct AddBookmarkView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) var moc
    @Environment(\.keyboardShortcut) var keyboardShortcut
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Folder.index, ascending: true)]) var folders: FetchedResults<Folder>
    
    @State private var url = ""
    @State private var host = ""
    @State private var title = ""
    @State private var notes = ""
    @State private var folder: Folder?
    
    @FocusState var isURLFieldActive: Bool
    @FocusState var isNotesFieldActive: Bool
    
    @State private var addingNewFolder = false
    
    @AppStorage("removeTrackingParameters") var removeTrackingParameters = false
    
    var pasteboardContents: String? {
        if !isMacCatalyst, #available(iOS 16.0, *) {
            return nil
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
    
    @State private var askForTitle = false
    @State private var isLoading = false
    var isValidURL: Bool {
        if URL(string: url)?.sanitise != nil {
            return true
        } else {
            return false
        }
    }
    
    init(urlString: String = "", folderPreset: Folder? = nil, onComplete completionAction: @escaping (Bool) -> Void = {_ in }) {
        _url = State(initialValue: urlString)
        _folder = State(initialValue: folderPreset)
        self.completionAction = completionAction
    }
    
    var completionAction: (Bool) -> Void
    
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
                            .focused($isURLFieldActive)
                        
                        Divider()
                        
                        pasteButton()
                    }
                } footer: {
                    if removeTrackingParameters {
                        Text("You have remove tracking parameters enabled, this will remove any content after **?** in the URL.")
                    }
                }
                
                
                if askForTitle {
                    Section(footer: Text("The URL you entered does not have a title by itself, you will have to type your own")) {
                        TextField("Title", text: $title)
                            .autocapitalization(.none)
                            .submitLabel(.done)
                    }
                }
                
                Section {
                    Picker("Folder", selection: $folder.animation()) {
                        Text("None").tag(nil as Folder?)
                        
                        ForEach(folders, id: \.self) { folder in
                            folderPickerItem(for: folder)
                                .tag(folder as Folder?)
                        }
                    }
                    
                    Button {
                        addingNewFolder.toggle()
                    } label: {
                        Text("Create New Folder")
                    }
                } footer: {
                    if folder == nil {
                        Text("Selecting \"None\" will cause this bookmark to only appear in the All Bookmarks section of the app")
                    }
                }
                
                Section {
                    TextEditor(text: $notes)
                        .placeholder("Add notes (optional)", contents: notes)
                        .focused($isNotesFieldActive)
                        .frame(height: 150)
                        .toolbar {
                            ToolbarItemGroup(placement: .keyboard) {
                                Spacer()
                                
                                Button(isNotesFieldActive == true ? "Done" : "") {
                                    isNotesFieldActive = false
                                }.allowsHitTesting(isNotesFieldActive)
                            }
                        }
                }
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    if isLoading {
                        ProgressView()
                            .opacity(0.7)
                    } else {
                        Button("Add", action: addBookmark)
                            .disabled(!isValidURL || title.isEmpty)
                            .keyboardShortcut("s", modifiers: .command)
                    }
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                        completionAction(false)
                    }
                    .keyboardShortcut(.cancelAction)
                }
            }
            .navigationBarTitle(title.isEmpty ? "New Bookmark" : title)
            .navigationViewStyle(.stack)
        }
        .sheet(isPresented: $addingNewFolder) {
            AddFolderView()
        }
        .onChange(of: url) { newURL in
            askForTitle = false
            title = ""
            host = ""
            
            fetchTitle(url: newURL)
        }
        .onAppear {
            if !url.isEmpty {
                fetchTitle(url: url)
            } else {
                isURLFieldActive = true
            }
        }
        .animation(.default, value: askForTitle)
    }
    
    func fetchTitle(url: String) {
        if let url = URL(string: url)?.sanitise {
            Task {
                isLoading = true
                if let metadata = try await startFetchingMetadata(for: url, fetchSubresources: false, timeout: 10) {
                    if let URLTitle = metadata.title {
                        if title.isEmpty {
                            self.title = URLTitle
                            askForTitle = false
                        }
                    } else {
                        askForTitle = true
                    }
                    
                    if let URLHost = url.host ?? metadata.originalURL?.host ?? metadata.url?.host{
                        self.host = URLHost
                    } else {
                        self.host = url.absoluteString
                    }
                } else {
                    if let URLHost = url.host {
                        self.host = URLHost
                    } else {
                        self.host = url.absoluteString
                    }
                }
                
                if title.isEmpty {
                    askForTitle = true
                }
                
                isLoading = false
            }
        }
    }
    
    func pasteButton() -> some View {
        Group {
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
    
    func addBookmark() {
        var sanitisedURL = URL(string: url)?.sanitise.absoluteString ?? url
        if removeTrackingParameters && !sanitisedURL.contains("youtube.com/watch") {
            sanitisedURL = sanitisedURL.components(separatedBy: "?").first ?? sanitisedURL
        }
        
        BookmarksManager.shared.addBookmark(title: title, url: sanitisedURL, host: host, notes: notes, folder: folder)
        
        dismiss()
        completionAction(true)
    }
    
    func folderPickerItem(for folder: Folder) -> some View {
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
