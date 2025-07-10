//
//  AddFolderView.swift
//  Marked
//
//  Created by Om Chachad on 27/04/22.
//

import SwiftUI
import CoreData

struct AddFolderView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.managedObjectContext) var moc
    @Environment(\.keyboardShortcut) var keyboardShortcut
    
    var existingFolder: Folder?
    var parentFolder: Folder?
    
    @State private var title = ""
    @State private var folderIconColor: ColorOption = .gray
    @State private var chosenSymbol = "folder.fill"

    @State private var chosenSymbolCategory: SymbolCategory = .objects
    
    var rows = Array(repeating: GridItem(.flexible()), count: 3)
    var completionAction: (Bool) -> Void
    
    init(existingFolder folder: Folder? = nil, onComplete completionAction: @escaping (Bool) -> Void = {_ in }) {
        self.existingFolder = folder
        self.parentFolder = existingFolder?.parentFolder
        if let folder {
            self._title = State(initialValue: folder.wrappedTitle)
            self._folderIconColor = State(initialValue: ColorOption(rawValue: folder.accentColor ?? "gray")!)
            self._chosenSymbol = State(initialValue: folder.wrappedSymbol)
        }
        self.completionAction = completionAction
    }
    
    init(parentFolder: Folder? = nil, onComplete completionAction: @escaping (Bool) -> Void = {_ in }) {
        self.parentFolder = parentFolder
        self.completionAction = completionAction
    }
    
    init(onComplete completionAction: @escaping (Bool) -> Void = {_ in }) {
        self.parentFolder = nil
        self.completionAction = completionAction
        self.existingFolder = nil
    }
    
    var body: some View {
        #if os(macOS)
        FormContents()
            .frame(maxWidth: 500, maxHeight: 550)
        #else
        NavigationView {
            FormContents()
                .navigationViewStyle(.stack)
                .navigationTitle(title.isEmpty ? (existingFolder == nil ? "New Folder" : "Edit Folder") : title)
        }
        #endif
    }
    
    func FormContents() -> some View {
        Form {
            if let parentFolder {
                Section {
                    HStack {
                        Text("This folder will be created in")
                        
                        Spacer()
                        
                        Group {
                            Image(systemName: parentFolder.wrappedSymbol)
                            Text(parentFolder.wrappedTitle)
                        }
                        .foregroundColor(parentFolder.wrappedColor)
                    }
                }
                #if !os(macOS)
                .font(.system(size: 14))
                #endif
            }
            
            Section {
                VStack {
                    Image(systemName: chosenSymbol)
                        .font(.largeTitle)
                        .foregroundColor(.white)
                        .padding()
                        .frame(width: 75, height: 75)
                        .background(folderIconColor.color.gradientify(colorScheme: colorScheme), in: Circle())
                        .shadow(color: folderIconColor.color, radius: 3)
                        .padding()
                        
                    TextField("Title", text: $title)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .padding()
                    #if !os(macOS)
                        .submitLabel(.done)
                    #if os(visionOS)
                        .background(.ultraThickMaterial)
                    #else
                        .background(colorScheme == .dark ? Color(UIColor.systemGray3) : Color(UIColor.systemGray5))
                    #endif
                        .cornerRadius(10, style: .continuous)
                        .padding(.bottom)
                    #else
                        .labelsHidden()
                        .textFieldStyle(.roundedBorder)
                    #endif
                }
            }
            
            
            Section {
                HStack {
                    Spacer()
                    LazyHGrid(rows: Array(repeating: GridItem(.flexible()), count: 2), spacing: 10) {
                        ForEach(ColorOption.allCases, id: \.self) { colorKey in
                            Circle()
                                .foregroundStyle(colorKey.color.gradientify(colorScheme: colorScheme))
                                .frame(width: 30)
                            #if !os(macOS)
                                .hoverEffect(.lift)
                            #endif
                                .padding(4)
                                .overlay(Circle().stroke(Color.accentColor, lineWidth: folderIconColor == colorKey ? 2.5 : 0.0))
                                .padding(2)
                                .onTapGesture {
                                        folderIconColor = colorKey
                                }
                        }
                    }
                    .frame(height: 100)
                    Spacer()
                }
            }
            
            Section {
                VStack {
                    ScrollView(.horizontal) {
                        LazyHGrid(rows: rows) {
                            ForEach(chosenSymbolCategory.symbolKeys, id: \.self) { symbol in
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .opacity(chosenSymbol == symbol ? 0.15 : 0)

                                    Image(systemName: symbol)
                                        .foregroundColor(.secondary)
                                }
                                .frame(width: 40, height: 40)
                                .contentShape(RoundedRectangle(cornerRadius: 10))
                                #if !os(macOS)
                                .hoverEffect(.highlight)
                                #endif
                                .onTapGesture {
                                    chosenSymbol = symbol
                                }
                            }
                        }
                        .frame(maxWidth: .infinity,  minHeight: 130, maxHeight: 130)
                        .padding(.vertical, 5)
                    }
                    
                    Picker("Choose", selection: $chosenSymbolCategory) {
                        ForEach(SymbolCategory.allCases, id: \.self) {
                            Text($0.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .padding(.bottom)
                }
            }
            
        }
        .groupedFormStyle()
        .toolbar(content: toolbarItems)
    }
    
    func toolbarItems() -> some ToolbarContent {
        Group {
            ToolbarItem(placement: .confirmationAction) {
                Group {
                    if existingFolder == nil {
                        Button("Add", action: addFolder)
                    } else {
                        Button("Save", action: saveChangesToFolder)
                    }
                }
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .keyboardShortcut("s", modifiers: .command)
            }
            
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    completionAction(false)
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
            }
        }
    }
    
    func addFolder() {
        if #available(iOS 16.0, macOS 13.0, *) {
            Task {
                let folder = try! await AddFolder(folderTitle: title, icon: chosenSymbol, color: folderIconColor.rawValue).perform().value
                if let folder {
                    FoldersManager.shared.findFolder(withId: folder.id).parentFolder = parentFolder
                    try? moc.save()
                }
            }
        } else {
            let _ = FoldersManager.shared.addFolder(title: title, accentColor: folderIconColor.rawValue, chosenSymbol: chosenSymbol, parentFolder: parentFolder)
        }
        
        completionAction(true)
        dismiss()
    }
    
    func saveChangesToFolder() {
        Task {
            existingFolder!.title = self.title
            existingFolder!.accentColor = self.folderIconColor.rawValue
            existingFolder!.symbol = self.chosenSymbol
            existingFolder!.parentFolder = self.parentFolder
            if moc.hasChanges {
                try? DataController.shared.persistentCloudKitContainer.viewContext.save()
            }
        }
        dismiss()
    }
    
    func getRecordsCount() -> Int? {
         let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Folder")
         do {
             let count = try moc.count(for: fetchRequest)
             return count
         } catch {
             print(error.localizedDescription)
         }
            return nil
     }
}

struct AddFolderView_Previews: PreviewProvider {
    static var previews: some View {
        AddFolderView()
    }
}
