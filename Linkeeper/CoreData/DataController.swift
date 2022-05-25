//
//  DataController.swift
//  Linkeeper
//
//  Created by Om Chachad on 25/05/22.
//

import CoreData
import Foundation

class DataController: ObservableObject {
    let container = NSPersistentContainer(name: "Linkeeper")
    
    init() {
        container.loadPersistentStores { description, error in
            if let error = error {
                print("Core Data failed to load: \(error.localizedDescription)")
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
    
    //func addBookmark
}
