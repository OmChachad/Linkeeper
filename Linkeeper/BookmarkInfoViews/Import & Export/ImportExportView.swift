//
//  ImportExportView.swift
//  Linkeeper
//
//  Created by Om Chachad on 02/01/24.
//

import SwiftUI

struct ImportExportView: View {
    let importExportHandler = ImportExportHandler()
    
    @State private var isImportingFromSafariOrChrome = false
    @State private var showingImporter = false
    @State private var isExporting = false
    @State private var htmlContent = ""
    
    @State private var totalBookmarks = 0
    @State private var importedBookmarks = 0
    @State private var failedImportCount = 0
    
    @State private var showingSuccessAlert = false
    @State private var showingError = false
    
    @State private var errorMessage = ""
    
    var body: some View {
        Section {
            Button("Import from Safari or Chrome") {
                isImportingFromSafariOrChrome.toggle()
            }
            
            Button("Export All Bookmarks") {
                isExporting.toggle()
            }
        } header: {
            Text("Import/Export Bookmarks")
        } footer: {
            Text("To import bookmarks, first export them as an HTML file from Safari or Chrome. Then, select the exported file from Linkeeper.")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .fileExporter(isPresented: $isExporting, document: ImportExportHandler().exportContents, contentType: .plainText, defaultFilename: fileName) { result in
            switch result {
                case .success(let url):
                    print("Saved to \(url)")
                case .failure(let error):
                    print(error.localizedDescription)
                }
        }
        .fileImporter(isPresented: $isImportingFromSafariOrChrome, allowedContentTypes: [.html]) { result in
            do {
                let fileURL = try result.get()
                let startedAccessing = fileURL.startAccessingSecurityScopedResource()
                self.htmlContent = try String(contentsOf: fileURL)

                do {
                    let result = try importExportHandler.importFromSafari(html: htmlContent)
                    self.importedBookmarks = result.importedBookmarks
                    self.totalBookmarks = result.totalBookmarks
                    self.failedImportCount = result.failedImportCount
                    showingSuccessAlert.toggle()
                } catch {
                    errorMessage = error.localizedDescription
                    showingError = true
                }
                if startedAccessing {
                    fileURL.stopAccessingSecurityScopedResource()
                }
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
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
                isImportingFromSafariOrChrome.toggle()
            }
            Button("Cancel", role: .cancel) {
                showingError.toggle()
            }
        } message: {
            Text("\(errorMessage) Please try again with another file.")
        }

    }
    
    var fileName: String {
        return "Linkeeper Archive \(Date().formatted(date: .numeric, time: .standard).replacingOccurrences(of: "/", with: "-").replacingOccurrences(of: ":", with: ".")).md"
    }
}

#Preview {
    ImportExportView()
}
