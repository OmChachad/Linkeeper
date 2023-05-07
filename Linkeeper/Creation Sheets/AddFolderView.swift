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
    
    @State private var title = ""
    @State private var accentColor = "gray"
    @State private var chosenSymbol = "car.fill"

    @State private var symbolCategories = ["Objects", "People", "Symbols"]
    @State private var chosenSymbolCategory = 0
    
    var rows = Array(repeating: GridItem(.flexible()), count: 3)
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    VStack() {
                    Image(systemName: chosenSymbol)
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                        .padding()
                        .background(Circle().foregroundColor(ColorOptions.values[accentColor]))
                        .shadow(color: ColorOptions.values[accentColor] ?? .red, radius: 3)
                        .drawingGroup()
                        .padding()
                        
                        
                    TextField("Title", text: $title)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .submitLabel(.done)
                        .padding()
                        .background(colorScheme == .dark ? Color(UIColor.systemGray3) : Color(UIColor.systemGray5))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .padding(.bottom)
                    }
                }
                
                
                Section {
                    HStack {
                        Spacer()
                        LazyHGrid(rows: Array(repeating: GridItem(.flexible()), count: 2), spacing: 10) {
                            ForEach(ColorOptions.keys, id: \.self) { colorKey in
                                Circle()
                                    .foregroundColor(ColorOptions.values[colorKey])
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
                                ForEach(symbols[chosenSymbolCategory], id: \.self) { symbol in
                                    
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 10)
                                            .frame(width: 40, height: 40)
                                            .opacity(chosenSymbol == symbol ? 0.15 : 0)
                                        
                                        Image(systemName: symbol)
                                            .foregroundColor(.secondary)
                                            .onTapGesture {
                                                chosenSymbol = symbol
                                            }
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity,  minHeight: 130, maxHeight: 130)
                            .padding(.vertical, 5)
                        }
                        Picker("Choose", selection: $chosenSymbolCategory) {
                            ForEach(0..<3) {
                                Text(symbolCategories[$0])
                            }
                        } .pickerStyle(.segmented)
                            .padding(.bottom)
                    }
                }
                
            }
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Add") {
                            let newFolder = Folder(context: moc)
                            newFolder.id = UUID()
                            newFolder.title = self.title
                            newFolder.accentColor = self.accentColor
                            newFolder.symbol = self.chosenSymbol
                            newFolder.index = Int16((folders.last?.index ?? 0) + 1)
                            if moc.hasChanges {
                                try? moc.save()
                            }
                            dismiss()
                        }
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .keyboardShortcut("s", modifiers: .command)
                    }
                    
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                        .keyboardShortcut(.cancelAction)
                    }

                }
                .navigationViewStyle(.stack)
                .navigationTitle(title.isEmpty ? "New Folder" : title)
        }
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
