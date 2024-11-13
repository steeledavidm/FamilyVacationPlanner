//
//  DataController.swift
//  FamilyVacationPlanner
//
//  Created by David Steele on 6/21/24.
//

import CoreData
import Foundation

@Observable
class DataController {
    static let shared = DataController()
    
    static var preview: NSManagedObjectContext {
        get {
            let container = NSPersistentContainer(name: "FamilyVacationPlanner")
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
            container.loadPersistentStores {_, _ in }
            addMockData(moc: container.viewContext)
            return container.viewContext
        }
    }
    
    let container: NSPersistentCloudKitContainer
    
    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "FamilyVacationPlanner")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        
        if inMemory {
            DataController.addMockData(moc: container.viewContext)
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}


extension DataController {
    static func addMockData(moc: NSManagedObjectContext) {
        let location1 = Location(context: moc)
        location1.name = "Start Location"
        location1.title = "XXX Street Name, City, ST  XXXXX, Country"
        location1.overNightStop = false
        location1.startLocation = true
//        location1.dateLeave = Date()
//        location1.dateArrive = Date() + 60*60*24*2 // 2 days in the future
        location1.latitude = 42.0
        location1.longitude = -92.0
        location1.locationIndex = 0
        location1.numberOfNights = 0
        
        let location2 = Location(context: moc)
        location2.name = "Over night stop"
        location2.title = "XXX Street Name, City, ST  XXXXX, Country"
        location2.overNightStop = true
        location2.startLocation = false
//        location2.dateLeave = Date() + 86400 // leave tomorrow
//        location2.dateArrive = Date()  // arrive today
        location2.latitude = 42.0
        location2.longitude = -130.0
        location2.locationIndex = 99
        location1.numberOfNights = 2
        
        let location3 = Location(context: moc)
        location3.name = "Day trip"
        location3.title = "XXX Street Name, City, ST  XXXXX, Country"
        location3.overNightStop = false
        location3.startLocation = false
//        location3.dateLeave = Date() + 86400 // leave tomorrow
//        location3.dateArrive = Date() + 86400 //arrive tomorrow
        location3.latitude = 20.0
        location3.longitude = -130.0
        location3.locationIndex = 1
        location1.numberOfNights = 0
        
        let trip1 = Trip(context: moc)
        trip1.tripName = "Trip 1"
        trip1.oneWay = false
        trip1.startDate = Date()
        trip1.endDate = Date() + 86400 * 2 // 2 days in the future
        trip1.location = [location1, location2, location3]
        
        let trip2 = Trip(context: moc)
        trip2.tripName = "Trip 2"
        trip2.oneWay = true
        trip2.startDate = Date()  + 86400 * 10 // 10 days in the future
        trip2.endDate = Date() + 86400 * 20 // 20 days in the future
        trip2.location = [location1, location2, location3]
    
        
        try? moc.save()
    }
}


