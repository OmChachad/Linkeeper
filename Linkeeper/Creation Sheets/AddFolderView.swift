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
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Folder.index, ascending: true)]) var folders: FetchedResults<Folder>
    
    var existingFolder: Folder?
    
    @State private var title = ""
    @State private var accentColor: ColorOption = .gray
    @State private var chosenSymbol = "car.fill"

    @State private var chosenSymbolCategory: SymbolCategory = .objects
    
    var rows = Array(repeating: GridItem(.flexible()), count: 3)
    var completionAction: (Bool) -> Void
    
    init(existingFolder folder: Folder? = nil, onComplete completionAction: @escaping (Bool) -> Void = {_ in }) {
        self.existingFolder = folder
        if let folder {
            self._title = State(initialValue: folder.wrappedTitle)
            self._accentColor = State(initialValue: ColorOption(rawValue: folder.accentColor ?? "gray")!)
            self._chosenSymbol = State(initialValue: folder.wrappedSymbol)
        }
        self.completionAction = completionAction
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    VStack {
                        Image(systemName: chosenSymbol)
                            .font(.largeTitle)
                            .foregroundColor(.white)
                            .padding()
                            .frame(width: 75, height: 75)
                            .background(accentColor.color, in: Circle())
                            .shadow(color: accentColor.color, radius: 3)
                            .padding()
                            
                            
                        TextField("Title", text: $title)
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .submitLabel(.done)
                            .padding()
                            .background(colorScheme == .dark ? Color(UIColor.systemGray3) : Color(UIColor.systemGray5))
                            .cornerRadius(10, style: .continuous)
                            .padding(.bottom)
                    }
                }
                
                
                Section {
                    HStack {
                        Spacer()
                        LazyHGrid(rows: Array(repeating: GridItem(.flexible()), count: 2), spacing: 10) {
                            ForEach(ColorOption.allCases, id: \.self) { colorKey in
                                Circle()
                                    .foregroundColor(colorKey.color)
                                    .frame(width: 30)
                                    .padding(4)
                                    .overlay(Circle().stroke(Color.blue, lineWidth: colorKey == accentColor ? 2.5 : 0.0))
                                    .padding(2)
                                    .onTapGesture {
                                            accentColor = colorKey
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
                        .padding(.bottom)
                    }
                }
                
            }
                .toolbar {
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
                .navigationViewStyle(.stack)
                .navigationTitle(title.isEmpty ? (existingFolder == nil ? "New Folder" : "Edit Folder") : title)
        }
    }
    
    func addFolder() {
        FoldersManager.shared.addFolder(title: title, accentColor: accentColor.rawValue, chosenSymbol: chosenSymbol)
        
        completionAction(true)
        dismiss()
    }
    
    func saveChangesToFolder() {
        existingFolder!.title = self.title
        existingFolder!.accentColor = self.accentColor.rawValue
        existingFolder!.symbol = self.chosenSymbol
        if moc.hasChanges {
            try? moc.save()
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
