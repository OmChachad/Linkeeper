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
        #if os(macOS)
        return NSPasteboard.general.string(forType: .string) ?? NSPasteboard.general.string(forType: .URL)
        #else
        if #available(iOS 16.0, *) {
            return nil
        } else {
            return UIPasteboard.general.string
        }
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
        Group {
            #if os(macOS)
            FormContents()
            #else
            NavigationView {
                FormContents()
                    .navigationTitle(title.isEmpty ? "New Bookmark" : title)
                    .navigationViewStyle(.stack)
            }
            #endif
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
    
    func FormContents() -> some View {
        Form {
            Section {
                HStack {
                    TextField("URL", text: $url)
                    #if !os(macOS)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        .submitLabel(.done)
                    #endif
                        .disableAutocorrection(true)
                        .focused($isURLFieldActive)
                    
                    Divider()
                    
                    pasteButton()
                }
            } footer: {
                if removeTrackingParameters {
                    Text("You have remove tracking parameters enabled, this will remove any content after **?** in the URL.")
                        .foregroundColor(.secondary)
                }
            }
            
            
            if askForTitle {
                Section(footer: Text("The URL you entered does not have a title by itself, you will have to type your own").foregroundColor(.secondary)) {
                    TextField("Title", text: $title)
#if !os(macOS)
                        .autocapitalization(.none)
                        .submitLabel(.done)
                    #endif
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
                .buttonStyle(.borderless)
                .tint(.accentColor)
            } footer: {
                if folder == nil {
                    Text("Selecting \"None\" will cause this bookmark to only appear in the All Bookmarks section of the app")
                        .foregroundColor(.secondary)
                }
            }
            
            Section("Notes (Optional)") {
                TextEditor(text: $notes)
                    #if !os(macOS)
                    .placeholder("Add notes (optional)", contents: notes)
                    #else
                    .scrollContentBackground(visibility: .hidden)
                    #endif
                    .focused($isNotesFieldActive)
                    .frame(height: 150)
                    .toolbar {
                        #if !os(visionOS)
                        ToolbarItemGroup(placement: .keyboard) {
                            Spacer()
                            
                            Button(isNotesFieldActive == true ? "Done" : "") {
                                isNotesFieldActive = false
                            }.allowsHitTesting(isNotesFieldActive)
                        }
                        #endif
                    }
            }
            #if !os(macOS)
            .labelsHidden()
            #endif
        }
        .groupedFormStyle()
        .toolbar(content: toolbarContents)
    }
    
    func toolbarContents() -> some ToolbarContent {
        Group {
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
            if #available(iOS 16.0, macOS 13.0, *) {
                PasteButton(payloadType: URL.self) { content in
                    if let url = content.first {
                        self.url = url.absoluteString
                    }
                }
                .labelStyle(.iconOnly)
                #if !os(macOS)
                .buttonBorderShape(.capsule)
                .offset(x: 5)
                #endif
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
        
        if #available(iOS 16.0, macOS 13.0, *) {
            Task {
                let bookmark = try! await AddBookmark(bookmarkTitle: title, url: URL(string: sanitisedURL)!, notes: notes).perform()
                if let bookmark = bookmark.value {
                    BookmarksManager.shared.findBookmark(withId: bookmark.id).folder = folder
                    try? moc.save()
                }
            }
        } else {
            BookmarksManager.shared.addBookmark(title: title, url: sanitisedURL, host: host, notes: notes, folder: folder)
        }
        
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
