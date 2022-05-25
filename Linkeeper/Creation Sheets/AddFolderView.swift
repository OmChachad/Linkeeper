//
//  AddFolderView.swift
//  Marked
//
//  Created by Om Chachad on 27/04/22.
//

import SwiftUI

struct AddFolderView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    @ObservedObject var folders: Folders
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
                        .background(Circle().foregroundColor(FolderColorOptions.values[accentColor]))
                        .shadow(color: FolderColorOptions.values[accentColor] ?? .red, radius: 3)
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
                            ForEach(FolderColorOptions.keys, id: \.self) { colorKey in
                                Circle()
                                    .foregroundColor(FolderColorOptions.values[colorKey])
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
                    Button("Add") {
                        folders.items.append(Folder(title: title, symbol: chosenSymbol, accentColor: accentColor))
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                }
                .navigationTitle(title.isEmpty ? "New Folder" : title)
        }
    }
}

struct AddFolderView_Previews: PreviewProvider {
    static var previews: some View {
        AddFolderView(folders: Folders())
    }
}
