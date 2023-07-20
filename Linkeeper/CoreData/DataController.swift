//
//  DataController.swift
//  Linkeeper
//
//  Created by Om Chachad on 25/05/22.
//

import CoreData
import Foundation

class DataController: ObservableObject {
    static let shared = DataController()
    
    let persistentCloudKitContainer: NSPersistentCloudKitContainer
        
    init() {
        persistentCloudKitContainer = NSPersistentCloudKitContainer(name: "Linkeeper")
        
        var oldStoreURL: URL?
        if let storeDescription = persistentCloudKitContainer.persistentStoreDescriptions.first, let url = storeDescription.url {
            oldStoreURL = FileManager.default.fileExists(atPath: url.path) ? url : nil
        }
        
        let sharedStoreURL = URL.storeURL(for: "group.starlightapps.linkeeper", databaseName: "Linkeeper")
        if oldStoreURL == nil {
            let storeDescription = NSPersistentStoreDescription(url: sharedStoreURL)
            persistentCloudKitContainer.persistentStoreDescriptions = [storeDescription]
        }
        
        guard let description = persistentCloudKitContainer.persistentStoreDescriptions.first else {
            fatalError ("Failed to initialize persistent container")
        }
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: "iCloud.org.starlightapps.Linkeeper")
        persistentCloudKitContainer.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        persistentCloudKitContainer.viewContext.automaticallyMergesChangesFromParent = true
        persistentCloudKitContainer.loadPersistentStores { storeDescription, error in
            if let error = error {
                fatalError("Core Data failed to load: \(error.self)")
            }
            
            // Moving old Core Data Store to App Group (from: https://stackoverflow.com/a/57020353)
            if let oldStoreURL, oldStoreURL.absoluteString != sharedStoreURL.absoluteString {
                let coordinator = self.persistentCloudKitContainer.persistentStoreCoordinator
                if let oldStore = coordinator.persistentStore(for: oldStoreURL) {
                    do {
                        try coordinator.migratePersistentStore(oldStore, to: sharedStoreURL, options: nil, withType: NSSQLiteStoreType)
                        
                        // Code to delete the previous persistent store (from: https://stackoverflow.com/a/72585271)
                        try coordinator.destroyPersistentStore(at: oldStoreURL, ofType: NSSQLiteStoreType, options: nil)
                        NSFileCoordinator(filePresenter: nil).coordinate(writingItemAt: oldStoreURL.deletingLastPathComponent(), options: .forDeleting, error: nil, byAccessor: { url in
                            try? FileManager.default.removeItem(at: url)
                            try? FileManager.default.removeItem(at: url.deletingLastPathComponent().appendingPathComponent("\(self.persistentCloudKitContainer.name).sqlite-shm"))
                            try? FileManager.default.removeItem(at: url.deletingLastPathComponent().appendingPathComponent("\(self.persistentCloudKitContainer.name).sqlite-wal"))
                            try? FileManager.default.removeItem(at: url.deletingLastPathComponent().appendingPathComponent("ckAssetFiles"))
                        })
                    } catch {
                        print(error.localizedDescription)
                    }
                    
                    // delete old store
                    let fileCoordinator = NSFileCoordinator(filePresenter: nil)
                    fileCoordinator.coordinate(writingItemAt: oldStoreURL, options: .forDeleting, error: nil, byAccessor: { url in
                        do {
                            try FileManager.default.removeItem(at: oldStoreURL)
                        } catch {
                            print(error.localizedDescription)
                        }
                    })
                }
            }
        }
        print(persistentCloudKitContainer.persistentStoreDescriptions)
        
        // This is to make sure there is no duplicate bookmark or folder.
        // Deduplicate bookmarks
        var uniqueBookmarks: Set<UUID> = Set()
        var bookmarksToDelete: [Bookmark] = []

        do {
            let bookmarks = try persistentCloudKitContainer.viewContext.fetch(Bookmark.fetchRequest())
            bookmarks.forEach { bookmark in
                if let id = bookmark.id {
                    if !uniqueBookmarks.contains(id) {
                        uniqueBookmarks.insert(id)
                    } else {
                        bookmarksToDelete.append(bookmark)
                    }
                }
            }
        } catch let error {
            print("Couldn't fetch all bookmarks: \(error.localizedDescription)")
        }

        bookmarksToDelete.forEach { bookmark in
            persistentCloudKitContainer.viewContext.delete(bookmark)
        }

        // Deduplicate folders
        var uniqueFolders: Set<UUID> = Set()
        var foldersToDelete: [Folder] = []

        do {
            let folders = try persistentCloudKitContainer.viewContext.fetch(Folder.fetchRequest())
            folders.forEach { folder in
                if let id = folder.id {
                    if !uniqueFolders.contains(id) {
                        uniqueFolders.insert(id)
                    } else {
                        foldersToDelete.append(folder)
                    }
                }
            }
        } catch let error {
            print("Couldn't fetch all folders: \(error.localizedDescription)")
        }

        foldersToDelete.forEach { folder in
            persistentCloudKitContainer.viewContext.delete(folder)
        }

        try? persistentCloudKitContainer.viewContext.save()

    }
    
    func deduplicate<T: NSManagedObject>(type: T.Type, idKeyPath: KeyPath<T, UUID?>) {
        guard let entityName = T.entity().name else {
            return
        }
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        request.returnsObjectsAsFaults = false
        
        do {
            let objects = try persistentCloudKitContainer.viewContext.fetch(request) as? [T] ?? []
            var uniqueIDs: Set<UUID> = Set()
            var objectsToDelete: [T] = []
            
            for object in objects {
                if let id = object[keyPath: idKeyPath] {
                    if uniqueIDs.contains(id) {
                        objectsToDelete.append(object)
                    } else {
                        uniqueIDs.insert(id)
                    }
                }
            }
            
            objectsToDelete.forEach { object in
                persistentCloudKitContainer.viewContext.delete(object)
            }
            
            try? persistentCloudKitContainer.viewContext.save()
        } catch let error {
            print("Couldn't fetch \(entityName): \(error.localizedDescription)")
        }
    }
    
    func save(context: NSManagedObjectContext) {
        do {
            try context.save()
        } catch {
            print("Error \(error.localizedDescription)")
        }
    }
}
