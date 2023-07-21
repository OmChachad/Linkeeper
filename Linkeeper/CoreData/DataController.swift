import CoreData
import Foundation

class DataController: ObservableObject {
    static let shared = DataController()

    let persistentCloudKitContainer: NSPersistentCloudKitContainer

    private init() {
        persistentCloudKitContainer = NSPersistentCloudKitContainer(name: "Linkeeper")

        let sharedStoreURL = URL.storeURL(for: "group.starlightapps.linkeeper", databaseName: "Linkeeper")

        if let oldStoreURL = persistentCloudKitContainer.persistentStoreDescriptions.first?.url, oldStoreURL.absoluteString != sharedStoreURL.absoluteString {
            migrateStore(from: oldStoreURL, to: sharedStoreURL)
        }
        
        setupPersistentStore(with: sharedStoreURL)
        configureContainer()
        deduplicateBookmarksAndFolders()
    }

    private func setupPersistentStore(with storeURL: URL) {
        let storeDescription = NSPersistentStoreDescription(url: storeURL)
        persistentCloudKitContainer.persistentStoreDescriptions = [storeDescription]
    }

    private func configureContainer() {
        guard let description = persistentCloudKitContainer.persistentStoreDescriptions.first else {
            fatalError("Failed to initialize persistent container")
        }

        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: "iCloud.org.starlightapps.Linkeeper")

        persistentCloudKitContainer.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        persistentCloudKitContainer.viewContext.automaticallyMergesChangesFromParent = true

        persistentCloudKitContainer.loadPersistentStores(completionHandler: { _, error in
            if let error = error {
                fatalError("Core Data failed to load: \(error)")
            }
        })
    }
    
    /// To delete the previous persistent store, and migrate it to the new location. (from: https://stackoverflow.com/a/72585271)
    /// - Parameters:
    ///   - oldStoreURL: The previous Core Data Store Location
    ///   - newStoreURL: The new Core Data Store Location
    private func migrateStore(from oldStoreURL: URL, to newStoreURL: URL) {
        let coordinator = persistentCloudKitContainer.persistentStoreCoordinator

        guard let oldStore = coordinator.persistentStore(for: oldStoreURL) else {
            return
        }

        do {
            try coordinator.migratePersistentStore(oldStore, to: newStoreURL, options: nil, withType: NSSQLiteStoreType)

            try coordinator.destroyPersistentStore(at: oldStoreURL, ofType: NSSQLiteStoreType, options: nil)
            try FileManager.default.removeItem(at: oldStoreURL.deletingLastPathComponent().appendingPathComponent("\(persistentCloudKitContainer.name).sqlite-shm"))
            try FileManager.default.removeItem(at: oldStoreURL.deletingLastPathComponent().appendingPathComponent("\(persistentCloudKitContainer.name).sqlite-wal"))
            try FileManager.default.removeItem(at: oldStoreURL.deletingLastPathComponent().appendingPathComponent("ckAssetFiles"))
            
            let fileCoordinator = NSFileCoordinator(filePresenter: nil)
            fileCoordinator.coordinate(writingItemAt: oldStoreURL, options: .forDeleting, error: nil, byAccessor: { url in
                do {
                    try FileManager.default.removeItem(at: oldStoreURL)
                } catch {
                    print(error.localizedDescription)
                }
            })
        } catch {
            print("Migration failed: \(error)")
        }
    }

    private func deduplicateBookmarksAndFolders() {
        deduplicate(type: Bookmark.self, idKeyPath: \.id)
        deduplicate(type: Folder.self, idKeyPath: \.id)
    }

    private func deduplicate<T: NSManagedObject>(type: T.Type, idKeyPath: KeyPath<T, UUID?>) {
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

            save()
        } catch {
            print("Couldn't fetch \(entityName): \(error)")
        }
    }

    func save() {
        do {
            let context = persistentCloudKitContainer.viewContext
            if context.hasChanges {
                try context.save()
            }
        } catch {
            print("Error \(error)")
        }
    }
}
