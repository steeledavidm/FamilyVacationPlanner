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
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        
        let mockTrip1 = Trip(context: moc)
        mockTrip1.startDate = dateFormatter.date(from: "Optional(2024-11-17 04:58:23 +0000)")
        mockTrip1.endDate = dateFormatter.date(from: "Optional(2024-11-18 04:58:00 +0000)")
        mockTrip1.tripName = "Test"
        mockTrip1.oneWay = false

        let mockLocation10 = Location(context: moc)
        mockLocation10.dateArrive = dateFormatter.date(from: "Optional(2024-11-18 04:58:00 +0000)")
        mockLocation10.dateLeave = dateFormatter.date(from: "Optional(2024-11-17 04:58:23 +0000)")
        mockLocation10.latitude = 42.40921792390283
        mockLocation10.locationIndex = 0
        mockLocation10.longitude = -92.44370455797238
        mockLocation10.modified = nil
        mockLocation10.name = "Home"
        mockLocation10.notes = ""
        mockLocation10.numberOfNights = 0
        mockLocation10.overNightStop = false
        mockLocation10.primary = false
        mockLocation10.requester = ""
        mockLocation10.startLocation = true
        mockLocation10.status = ""
        mockLocation10.subtitle = ""
        mockLocation10.title = "201 Whitetail Ridge, Hudson, IA  50643, United States"

        let mockLocation11 = Location(context: moc)
        mockLocation11.dateArrive = dateFormatter.date(from: "Optional(2024-11-16 06:00:00 +0000)")
        mockLocation11.dateLeave = dateFormatter.date(from: "Optional(2024-11-16 06:00:00 +0000)")
        mockLocation11.latitude = 40.743376753580144
        mockLocation11.locationIndex = 99
        mockLocation11.longitude = -96.64889077191648
        mockLocation11.modified = nil
        mockLocation11.name = "Grammy "
        mockLocation11.notes = ""
        mockLocation11.numberOfNights = 0
        mockLocation11.overNightStop = true
        mockLocation11.primary = false
        mockLocation11.requester = ""
        mockLocation11.startLocation = false
        mockLocation11.status = ""
        mockLocation11.subtitle = ""
        mockLocation11.title = "6827 S 52nd St, Lincoln, NE  68516, United States"
        mockLocation11.poiCategory = .hotel

        let mockLocation12 = Location(context: moc)
        mockLocation12.dateArrive = dateFormatter.date(from: "Optional(2024-11-17 06:00:00 +0000)")
        mockLocation12.dateLeave = dateFormatter.date(from: "Optional(2024-11-17 06:00:00 +0000)")
        mockLocation12.latitude = 39.1768402
        mockLocation12.locationIndex = 101
        mockLocation12.longitude = -94.4868612
        mockLocation12.modified = nil
        mockLocation12.name = "4545 NE Worlds of Fun Ave"
        mockLocation12.notes = ""
        mockLocation12.numberOfNights = 0
        mockLocation12.overNightStop = false
        mockLocation12.primary = false
        mockLocation12.requester = ""
        mockLocation12.startLocation = false
        mockLocation12.status = ""
        mockLocation12.subtitle = ""
        mockLocation12.title = "4545 NE Worlds of Fun Ave, Kansas City, MO  64161, United States"
        
        mockTrip1.location = [mockLocation10, mockLocation11, mockLocation12]
        
        let location1 = Location(context: moc)
        location1.name = "Start Location"
        location1.title = "XXX Street Name, City, ST  XXXXX, Country"
        location1.overNightStop = false
        location1.startLocation = true
        location1.dateLeave = Date()
        location1.dateArrive = Date() + 60*60*24*2 // 2 days in the future
        location1.latitude = 42.0
        location1.longitude = -92.0
        location1.locationIndex = 0
        location1.numberOfNights = 0
        location1.categoryRawValue = "airport"
        
        let location2 = Location(context: moc)
        location2.name = "Over night stop"
        location2.title = "XXX Street Name, City, ST  XXXXX, Country"
        location2.overNightStop = true
        location2.startLocation = false
        location2.dateLeave = Date() + 86400 // leave tomorrow
        location2.dateArrive = Date()  // arrive today
        location2.latitude = 42.0
        location2.longitude = -100.0
        location2.locationIndex = 99
        location2.numberOfNights = 2
        location1.categoryRawValue = "swimming"
        
        let location3 = Location(context: moc)
        location3.name = "Day trip"
        location3.title = "XXX Street Name, City, ST  XXXXX, Country"
        location3.overNightStop = false
        location3.startLocation = false
        location3.dateLeave = Date() + 86400 // leave tomorrow
        location3.dateArrive = Date() + 86400 //arrive tomorrow
        location3.latitude = 30.0
        location3.longitude = -100.0
        location3.locationIndex = 1
        location2.numberOfNights = 0
        
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
        
//        let mockTrip0 = Trip(context: moc)
//        mockTrip0.startDate = dateFormatter.date(from: "Optional(2024-07-19 17:09:00 +0000)")
//        mockTrip0.endDate = dateFormatter.date(from: "Optional(2024-08-06 17:09:00 +0000)")
//        mockTrip0.tripName = "2024 California Road Trip"
//        mockTrip0.oneWay = false
//
//
//        let mockLocation00 = Location(context: moc)
//        mockLocation00.dateArrive = dateFormatter.date(from: "Optional(2024-07-22 02:00:00 +0000)")
//        mockLocation00.dateLeave = dateFormatter.date(from: "Optional(2024-07-25 12:00:00 +0000)")
//        mockLocation00.latitude = 38.946527
//        mockLocation00.locationIndex = 299
//        mockLocation00.longitude = -119.955663
//        mockLocation00.modified = nil
//        mockLocation00.name = "South Lake Tahoe"
//        mockLocation00.notes = ""
//        mockLocation00.numberOfNights = 4
//        mockLocation00.overNightStop = true
//        mockLocation00.primary = true
//        mockLocation00.requester = "David Steele"
//        mockLocation00.startLocation = false
//        mockLocation00.status = "Review"
//        mockLocation00.subtitle = ""
//        mockLocation00.title = "1073 Ski Run Blvd, South Lake Tahoe, CA  96150, United States"
//
//        let mockLocation01 = Location(context: moc)
//        mockLocation01.dateArrive = dateFormatter.date(from: "Optional(2024-08-05 02:00:00 +0000)")
//        mockLocation01.dateLeave = dateFormatter.date(from: "Optional(2024-08-05 12:00:00 +0000)")
//        mockLocation01.latitude = 40.7433644
//        mockLocation01.locationIndex = 1799
//        mockLocation01.longitude = -96.6488979
//        mockLocation01.modified = nil
//        mockLocation01.name = "Grammy and Papa’s "
//        mockLocation01.notes = ""
//        mockLocation01.numberOfNights = 1
//        mockLocation01.overNightStop = true
//        mockLocation01.primary = true
//        mockLocation01.requester = "Requester"
//        mockLocation01.startLocation = false
//        mockLocation01.status = "Review"
//        mockLocation01.subtitle = ""
//        mockLocation01.title = "6827 S 52nd St, Lincoln, NE  68516, United States"
//
//        let mockLocation02 = Location(context: moc)
//        mockLocation02.dateArrive = dateFormatter.date(from: "Optional(2024-07-29 07:00:00 +0000)")
//        mockLocation02.dateLeave = dateFormatter.date(from: "Optional(2024-07-29 07:00:00 +0000)")
//        mockLocation02.latitude = 36.4909874
//        mockLocation02.locationIndex = 1001
//        mockLocation02.longitude = -118.8253253
//        mockLocation02.modified = nil
//        mockLocation02.name = "Sequoia National Park"
//        mockLocation02.notes = ""
//        mockLocation02.numberOfNights = 0
//        mockLocation02.overNightStop = false
//        mockLocation02.primary = true
//        mockLocation02.requester = "Requester"
//        mockLocation02.startLocation = false
//        mockLocation02.status = "Review"
//        mockLocation02.subtitle = ""
//        mockLocation02.title = "47050 Generals Hwy, Three Rivers, CA  93271, United States"
//
//        let mockLocation03 = Location(context: moc)
//        mockLocation03.dateArrive = dateFormatter.date(from: "Optional(2024-07-20 07:00:00 +0000)")
//        mockLocation03.dateLeave = dateFormatter.date(from: "Optional(2024-07-20 07:00:00 +0000)")
//        mockLocation03.latitude = 41.619435
//        mockLocation03.locationIndex = 101
//        mockLocation03.longitude = -112.543648
//        mockLocation03.modified = nil
//        mockLocation03.name = "Golden Spike National Historical Park - Engine House"
//        mockLocation03.notes = ""
//        mockLocation03.numberOfNights = 0
//        mockLocation03.overNightStop = false
//        mockLocation03.primary = true
//        mockLocation03.requester = "Requester"
//        mockLocation03.startLocation = false
//        mockLocation03.status = "Review"
//        mockLocation03.subtitle = ""
//        mockLocation03.title = "Promotory, UT 84337, United States"
//
//        let mockLocation04 = Location(context: moc)
//        mockLocation04.dateArrive = dateFormatter.date(from: "Optional(2024-07-29 07:00:00 +0000)")
//        mockLocation04.dateLeave = dateFormatter.date(from: "Optional(2024-07-29 07:00:00 +0000)")
//        mockLocation04.latitude = 36.694695
//        mockLocation04.locationIndex = 1002
//        mockLocation04.longitude = -118.872536
//        mockLocation04.modified = nil
//        mockLocation04.name = "Kings Canyon National Park Big Stump Entrance"
//        mockLocation04.notes = ""
//        mockLocation04.numberOfNights = 0
//        mockLocation04.overNightStop = false
//        mockLocation04.primary = true
//        mockLocation04.requester = "Requester"
//        mockLocation04.startLocation = false
//        mockLocation04.status = "Review"
//        mockLocation04.subtitle = ""
//        mockLocation04.title = "Generals Hwy, Kings Canyon National Pk, CA  93633, United States"
//
//        let mockLocation05 = Location(context: moc)
//        mockLocation05.dateArrive = dateFormatter.date(from: "Optional(2024-08-01 02:00:00 +0000)")
//        mockLocation05.dateLeave = dateFormatter.date(from: "Optional(2024-08-01 12:00:00 +0000)")
//        mockLocation05.latitude = 35.1638614
//        mockLocation05.locationIndex = 1299
//        mockLocation05.longitude = -120.6883322
//        mockLocation05.modified = nil
//        mockLocation05.name = "Spyglass Inn"
//        mockLocation05.notes = ""
//        mockLocation05.numberOfNights = 1
//        mockLocation05.overNightStop = true
//        mockLocation05.primary = true
//        mockLocation05.requester = "David Steele"
//        mockLocation05.startLocation = false
//        mockLocation05.status = "Review"
//        mockLocation05.subtitle = ""
//        mockLocation05.title = "2705 Spyglass Dr, Pismo Beach, CA  93449, United States"
//
//        let mockLocation06 = Location(context: moc)
//        mockLocation06.dateArrive = dateFormatter.date(from: "Optional(2024-08-03 17:09:00 +0000)")
//        mockLocation06.dateLeave = dateFormatter.date(from: "Optional(2024-08-04 17:09:00 +0000)")
//        mockLocation06.latitude = 39.3891674
//        mockLocation06.locationIndex = 1699
//        mockLocation06.longitude = -107.0826203
//        mockLocation06.modified = nil
//        mockLocation06.name = "The Hoffmann Basalt Aspen "
//        mockLocation06.notes = ""
//        mockLocation06.numberOfNights = 1
//        mockLocation06.overNightStop = true
//        mockLocation06.primary = true
//        mockLocation06.requester = "Requester"
//        mockLocation06.startLocation = false
//        mockLocation06.status = "Review"
//        mockLocation06.subtitle = ""
//        mockLocation06.title = "30 Kodiak Dr, Basalt, CO  81621, United States"
//
//        let mockLocation07 = Location(context: moc)
//        mockLocation07.dateArrive = dateFormatter.date(from: "Optional(2024-08-02 07:00:00 +0000)")
//        mockLocation07.dateLeave = dateFormatter.date(from: "Optional(2024-08-02 07:00:00 +0000)")
//        mockLocation07.latitude = 36.4055651
//        mockLocation07.locationIndex = 1401
//        mockLocation07.longitude = -114.5663612
//        mockLocation07.modified = nil
//        mockLocation07.name = "Valley of Fire State Park"
//        mockLocation07.notes = ""
//        mockLocation07.numberOfNights = 0
//        mockLocation07.overNightStop = false
//        mockLocation07.primary = true
//        mockLocation07.requester = "Requester"
//        mockLocation07.startLocation = false
//        mockLocation07.status = "Review"
//        mockLocation07.subtitle = ""
//        mockLocation07.title = "29450 Valley Of Fire Rd, Overton, NV 89040, United States"
//
//        let mockLocation08 = Location(context: moc)
//        mockLocation08.dateArrive = dateFormatter.date(from: "Optional(2024-07-29 02:00:00 +0000)")
//        mockLocation08.dateLeave = dateFormatter.date(from: "Optional(2024-07-31 12:00:00 +0000)")
//        mockLocation08.latitude = 36.3190303
//        mockLocation08.locationIndex = 999
//        mockLocation08.longitude = -119.3196569
//        mockLocation08.modified = nil
//        mockLocation08.name = "Visalia California"
//        mockLocation08.notes = ""
//        mockLocation08.numberOfNights = 3
//        mockLocation08.overNightStop = true
//        mockLocation08.primary = true
//        mockLocation08.requester = "David Steele"
//        mockLocation08.startLocation = false
//        mockLocation08.status = "Review"
//        mockLocation08.subtitle = ""
//        mockLocation08.title = "2609 W Iris Ave, Visalia, CA  93277, United States"
//
//        let mockLocation09 = Location(context: moc)
//        mockLocation09.dateArrive = dateFormatter.date(from: "Optional(2024-08-03 06:00:00 +0000)")
//        mockLocation09.dateLeave = dateFormatter.date(from: "Optional(2024-08-03 06:00:00 +0000)")
//        mockLocation09.latitude = 37.6403874
//        mockLocation09.locationIndex = 1501
//        mockLocation09.longitude = -112.1696423
//        mockLocation09.modified = nil
//        mockLocation09.name = "Bryce Canyon Visitor Center"
//        mockLocation09.notes = ""
//        mockLocation09.numberOfNights = 0
//        mockLocation09.overNightStop = false
//        mockLocation09.primary = true
//        mockLocation09.requester = "Requester"
//        mockLocation09.startLocation = false
//        mockLocation09.status = "Review"
//        mockLocation09.subtitle = ""
//        mockLocation09.title = "Highway 63, Bryce, UT 84776, United States"
//
//        let mockLocation010 = Location(context: moc)
//        mockLocation010.dateArrive = dateFormatter.date(from: "Optional(2024-07-21 02:00:00 +0000)")
//        mockLocation010.dateLeave = dateFormatter.date(from: "Optional(2024-07-21 12:00:00 +0000)")
//        mockLocation010.latitude = 39.5255771
//        mockLocation010.locationIndex = 199
//        mockLocation010.longitude = -119.8159075
//        mockLocation010.modified = nil
//        mockLocation010.name = "Plaza Resort Club Reno"
//        mockLocation010.notes = ""
//        mockLocation010.numberOfNights = 1
//        mockLocation010.overNightStop = true
//        mockLocation010.primary = true
//        mockLocation010.requester = "David Steele"
//        mockLocation010.startLocation = false
//        mockLocation010.status = "Review"
//        mockLocation010.subtitle = ""
//        mockLocation010.title = "121 West St, Reno, NV  89501, United States"
//
//        let mockLocation011 = Location(context: moc)
//        mockLocation011.dateArrive = dateFormatter.date(from: "Optional(2024-07-31 07:00:00 +0000)")
//        mockLocation011.dateLeave = dateFormatter.date(from: "Optional(2024-07-31 07:00:00 +0000)")
//        mockLocation011.latitude = 35.5218802
//        mockLocation011.locationIndex = 1301
//        mockLocation011.longitude = -121.0357781
//        mockLocation011.modified = nil
//        mockLocation011.name = "1100 Old Creamery Rd"
//        mockLocation011.notes = ""
//        mockLocation011.numberOfNights = 0
//        mockLocation011.overNightStop = false
//        mockLocation011.primary = true
//        mockLocation011.requester = "Requester"
//        mockLocation011.startLocation = false
//        mockLocation011.status = "Review"
//        mockLocation011.subtitle = ""
//        mockLocation011.title = "1100 Old Creamery Rd, Cambria, CA  93435, United States"
//
//        let mockLocation012 = Location(context: moc)
//        mockLocation012.dateArrive = dateFormatter.date(from: "Optional(2024-07-21 07:00:00 +0000)")
//        mockLocation012.dateLeave = dateFormatter.date(from: "Optional(2024-07-21 07:00:00 +0000)")
//        mockLocation012.latitude = 39.3242391
//        mockLocation012.locationIndex = 201
//        mockLocation012.longitude = -120.2322078
//        mockLocation012.modified = nil
//        mockLocation012.name = "Donner Memorial State Park"
//        mockLocation012.notes = ""
//        mockLocation012.numberOfNights = 0
//        mockLocation012.overNightStop = false
//        mockLocation012.primary = true
//        mockLocation012.requester = "Requester"
//        mockLocation012.startLocation = false
//        mockLocation012.status = "Review"
//        mockLocation012.subtitle = ""
//        mockLocation012.title = "12593 Donner Pass Rd, Truckee, CA 96161, United States"
//
//        let mockLocation013 = Location(context: moc)
//        mockLocation013.dateArrive = dateFormatter.date(from: "Optional(2024-07-26 02:00:00 +0000)")
//        mockLocation013.dateLeave = dateFormatter.date(from: "Optional(2024-07-28 12:00:00 +0000)")
//        mockLocation013.latitude = 37.548774
//        mockLocation013.locationIndex = 699
//        mockLocation013.longitude = -119.640503
//        mockLocation013.modified = nil
//        mockLocation013.name = "ChargePoint Yosemite"
//        mockLocation013.notes = ""
//        mockLocation013.numberOfNights = 3
//        mockLocation013.overNightStop = true
//        mockLocation013.primary = true
//        mockLocation013.requester = "David Steele"
//        mockLocation013.startLocation = false
//        mockLocation013.status = "Review"
//        mockLocation013.subtitle = ""
//        mockLocation013.title = "8038 Chilnualna Falls Rd, Yosemite National Park, CA  95389, United States"
//
//        let mockLocation014 = Location(context: moc)
//        mockLocation014.dateArrive = dateFormatter.date(from: "Optional(2024-08-05 17:09:00 +0000)")
//        mockLocation014.dateLeave = dateFormatter.date(from: "Optional(2024-07-19 17:09:00 +0000)")
//        mockLocation014.latitude = 42.4091812
//        mockLocation014.locationIndex = 0
//        mockLocation014.longitude = -92.4436358
//        mockLocation014.modified = nil
//        mockLocation014.name = "Home"
//        mockLocation014.notes = ""
//        mockLocation014.numberOfNights = 0
//        mockLocation014.overNightStop = false
//        mockLocation014.primary = true
//        mockLocation014.requester = "Requester"
//        mockLocation014.startLocation = true
//        mockLocation014.status = "Review"
//        mockLocation014.subtitle = ""
//        mockLocation014.title = "201 Whitetail Ridge, Hudson, IA  50643, United States"
//
//        let mockLocation015 = Location(context: moc)
//        mockLocation015.dateArrive = dateFormatter.date(from: "Optional(2024-08-02 02:00:00 +0000)")
//        mockLocation015.dateLeave = dateFormatter.date(from: "Optional(2024-08-02 12:00:00 +0000)")
//        mockLocation015.latitude = 36.1121843
//        mockLocation015.locationIndex = 1399
//        mockLocation015.longitude = -115.1681489
//        mockLocation015.modified = nil
//        mockLocation015.name = "Paris Las Vegas - Parking"
//        mockLocation015.notes = ""
//        mockLocation015.numberOfNights = 1
//        mockLocation015.overNightStop = true
//        mockLocation015.primary = true
//        mockLocation015.requester = "David Steele"
//        mockLocation015.startLocation = false
//        mockLocation015.status = "Review"
//        mockLocation015.subtitle = ""
//        mockLocation015.title = "3655 S Las Vegas Blvd, Las Vegas, NV  89109, United States"
//
//        let mockLocation016 = Location(context: moc)
//        mockLocation016.dateArrive = dateFormatter.date(from: "Optional(2024-08-03 02:00:00 +0000)")
//        mockLocation016.dateLeave = dateFormatter.date(from: "Optional(2024-08-04 12:00:00 +0000)")
//        mockLocation016.latitude = 37.628782
//        mockLocation016.locationIndex = 1499
//        mockLocation016.longitude = -112.081554
//        mockLocation016.modified = nil
//        mockLocation016.name = "Bryce Country Cabins"
//        mockLocation016.notes = ""
//        mockLocation016.numberOfNights = 2
//        mockLocation016.overNightStop = true
//        mockLocation016.primary = true
//        mockLocation016.requester = "David Steele"
//        mockLocation016.startLocation = false
//        mockLocation016.status = "Review"
//        mockLocation016.subtitle = ""
//        mockLocation016.title = "320 N Main St, Tropic, UT  84718, United States"
//
//        let mockLocation017 = Location(context: moc)
//        mockLocation017.dateArrive = dateFormatter.date(from: "Optional(2024-07-20 04:00:00 +0000)")
//        mockLocation017.dateLeave = dateFormatter.date(from: "Optional(2024-07-20 12:00:00 +0000)")
//        mockLocation017.latitude = 41.263327
//        mockLocation017.locationIndex = 99
//        mockLocation017.longitude = -110.981416
//        mockLocation017.modified = nil
//        mockLocation017.name = "Evanston Utah"
//        mockLocation017.notes = ""
//        mockLocation017.numberOfNights = 1
//        mockLocation017.overNightStop = true
//        mockLocation017.primary = true
//        mockLocation017.requester = "David Steele"
//        mockLocation017.startLocation = false
//        mockLocation017.status = "Review"
//        mockLocation017.subtitle = ""
//        mockLocation017.title = "1965 Harrison Dr, Evanston, WY  82930, United States"
//        
//        mockTrip0.location = [mockLocation00, mockLocation01, mockLocation02, mockLocation03, mockLocation04, mockLocation05, mockLocation06, mockLocation07, mockLocation08, mockLocation09, mockLocation010, mockLocation011, mockLocation012, mockLocation013, mockLocation014, mockLocation015, mockLocation016, mockLocation017]
    
        
        try? moc.save()
    }
}


