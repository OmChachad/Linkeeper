//
//  DataController.swift
//  Linkeeper
//
//  Created by Om Chachad on 25/05/22.
//

import CoreData
import Foundation

class DataController: ObservableObject {
    let persistentCloudKitContainer: NSPersistentCloudKitContainer
        
    init() {
        persistentCloudKitContainer = NSPersistentCloudKitContainer(name: "Linkeeper")
        guard let description = persistentCloudKitContainer.persistentStoreDescriptions.first else {
            fatalError ("Failed to initialize persistent container")
        }
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        persistentCloudKitContainer.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        persistentCloudKitContainer.viewContext.automaticallyMergesChangesFromParent = true
        
        persistentCloudKitContainer.loadPersistentStores { _, error in
            if let error = error {
                print("Core Data failed to load: \(error.self)")
            }
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
