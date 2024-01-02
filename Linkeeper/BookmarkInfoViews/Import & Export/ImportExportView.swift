//
//  ImportExportView.swift
//  Linkeeper
//
//  Created by Om Chachad on 02/01/24.
//

import SwiftUI

struct ImportExportView: View {
    let importExportHandler = ImportExportHandler()
    
    @State private var isImportingFromSafari = false
    @State private var showingImporter = false
    @State private var isExporting = false
    @State private var htmlContent = ""
    
    @State private var totalBookmarks = 0
    @State private var importedBookmarks = 0
    @State private var failedImportCount = 0
    
    @State private var showingSuccessAlert = false
    @State private var showingError = false
    
    var body: some View {
        Section("Import/Export Bookmarks") {
            Button("Import from Safari") {
                isImportingFromSafari.toggle()
            }
            
            Button("Export All Bookmarks") {
                isExporting.toggle()
            }
        }
        .fileExporter(isPresented: $isExporting, document: ImportExportHandler().exportContents, contentType: .plainText, defaultFilename: fileName) { result in
            switch result {
                case .success(let url):
                    print("Saved to \(url)")
                case .failure(let error):
                    print(error.localizedDescription)
                }
        }
        .fileImporter(isPresented: $isImportingFromSafari, allowedContentTypes: [.html]) { result in
            do {
                let fileURL = try result.get()
                self.htmlContent = try String(contentsOf: fileURL)

                do {
                    let result = try importExportHandler.importFromSafari(html: htmlContent)
                    self.importedBookmarks = result.importedBookmarks
                    self.totalBookmarks = result.totalBookmarks
                    self.failedImportCount = result.failedImportCount
                    showingSuccessAlert.toggle()
                } catch {
                    showingError.toggle()
                }
                
            } catch {
                print("File import error: \(error.localizedDescription)")
            }
        }
        .alert("Import Completed", isPresented: $showingSuccessAlert) {
            Button("Done") {
                showingSuccessAlert.toggle()
                totalBookmarks = 0
                importedBookmarks = 0
                failedImportCount = 0
            }
        } message: {
            if totalBookmarks == importedBookmarks {
                Text("Imported \(totalBookmarks) bookmarks successfully.")
            } else {
                Text("Imported \(importedBookmarks)/\(totalBookmarks) bookmarks. Could not import \(failedImportCount) bookmarks.")
            }
        }
        .alert("Failed to import bookmarks", isPresented: $showingError) {
            Button("Select another file...") {
                isImportingFromSafari.toggle()
            }
            Button("Cancel", role: .cancel) {
                showingError.toggle()
            }
        } message: {
            Text("An unknown error ocurred when trying to import bookmarks. Please try again with another file.")
        }

    }
    
    var fileName: String {
        return "Linkeeper Archive \(Date().formatted(date: .numeric, time: .standard).replacingOccurrences(of: "/", with: "-").replacingOccurrences(of: ":", with: ".")).md"
    }
}

#Preview {
    ImportExportView()
}
