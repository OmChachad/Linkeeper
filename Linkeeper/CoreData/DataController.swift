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
    }
    
    func save(context: NSManagedObjectContext) {
        do {
            try context.save()
        } catch {
            print("Error \(error.localizedDescription)")
        }
    }
}
