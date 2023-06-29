//
//  ImportView.swift
//  Linkeeper
//
//  Created by Om Chachad on 29/06/23.
//

import SwiftUI
import SwiftSoup

struct ImportView: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var importCompleted = false
    var htmlContents: String
    
    @Environment(\.managedObjectContext) var moc
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Folder.index, ascending: true)]) var folders: FetchedResults<Folder>
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Bookmark.date, ascending: true)]) var allBookmarks: FetchedResults<Bookmark>
    
    @State private var totalBookmarks: Double = 0
    @State private var importedBookmarks: Double = 0
    @State private var failedImportCount: Double = 0
    
    var body: some View {
        NavigationView {
            VStack {
                if importedBookmarks == totalBookmarks {
                    Image(systemName: "checkmark.circle.fill")
                        .imageScale(.large)
                        .foregroundColor(.green)
                    Text("Import Successful")
                        .bold()
                } else {
                    Text("\(importedBookmarks.formatted()) out of \(totalBookmarks.formatted()) imported.")
                    ProgressView(value: importedBookmarks, total: totalBookmarks)
                        .progressViewStyle(.linear)
                }
                
                if failedImportCount > 0 {
                    Text("^[Could not import \(failedImportCount) Bookmark](inflect: true)")
                }
            }
            .padding()
            .animation(.default, value: importedBookmarks)
            .toolbar {
                if importedBookmarks == totalBookmarks {
                    Button("Done", action: dismiss.callAsFunction)
                }
            }
        }
        .onAppear {
            do {
                // Parse the HTML content
                let doc = try SwiftSoup.parse(htmlContents)
                
                // Select all the <dt> elements that contain bookmarks
                let bookmarkElements = try doc.select("dt:has(a)")
                self.totalBookmarks = Double(bookmarkElements.count)
                // Iterate over each bookmark element
                for bookmarkElement in bookmarkElements {
                    // Retrieve the parent folder name
                    let parentFolder = try bookmarkElement.parent()?.previousElementSibling()?.text()
                    
                    // Retrieve the bookmark URL
                    guard let url = try bookmarkElement.select("a").first()?.attr("href") else {
                        failedImportCount += 1
                        continue
                    }
                    
                    // Retrieve the bookmark title
                    guard let title = try bookmarkElement.select("a").first()?.text() else {
                        failedImportCount += 1
                        continue
                    }
                    
                    importBookmark(url: url, title: title, folderName: parentFolder)
                    importedBookmarks += 1.0
                }
            } catch {
                print("Error parsing HTML: \(error)")
            }
        }
    }
    
    func importBookmark(url: String, title: String, folderName: String?) {
        let bookmark = Bookmark(context: moc)
        bookmark.id = UUID()
        bookmark.title = title
        bookmark.date = Date.now
        bookmark.host = URL(string: url)!.host
        bookmark.url = url
        
        if let folderName = folderName {
            if folderName == "Favorites" || folderName == "Favourites" {
                bookmark.isFavorited = true
            } else if folderName == "Bookmarks" {
                
            } else if let folder = folders.first(where: {$0.wrappedTitle == folderName}){
                bookmark.folder = folder
            } else {
                let folder = Folder(context: moc)
                folder.id = UUID()
                folder.title = folderName
                folder.symbol = "folder.fill"
                folder.accentColor = "gray"
                folder.index = (folders.last?.index ?? 0) + 1
                
                bookmark.folder = folder
                try? moc.save()
            }
        }
        
        try? moc.save()
    }
}

struct ImportView_Previews: PreviewProvider {
    static var previews: some View {
        ImportView(htmlContents: "")
    }
}
