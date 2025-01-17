//
//  LocationEditViewModel.swift
//  FamilyVacationPlanner
//
//  Created by David Steele on 11/21/24.
//

import CoreData
import Foundation
import MapKit
import SwiftUI

@Observable @MainActor
class LocationEditModel {
    let moc: NSManagedObjectContext
    var location: Location?
    var annotatedMapItem: AnnotatedMapItem?
    var trip: Trip?
    var name: String = ""
    var title: String = ""
    var poiCategory: MKPointOfInterestCategory = .airport
    var dateLeave: Date = Date()
    var dateArrive: Date = Date()
    var overNightStop: Bool = false
    var numberOfNights: Int16 = 0
    var locationIndex: Int16 = 0
    var notes: String = ""
    var startLocation: Bool = false
    var latitude: Double = 0.0
    var longitude: Double = 0.0
    var subtitle: String = ""
    
    init() {
        self.moc = DataController.shared.container.viewContext
        self.location = nil
        self.trip = nil
    }
    
    // Initialize for editing existing location
    init(location: Location) {
        self.moc = location.managedObjectContext ?? DataController.shared.container.viewContext
        self.location = location
        loadFromLocation(location)
    }
        
        // Init for creating new from map item
    init(annotatedMapItem: AnnotatedMapItem, context: NSManagedObjectContext = DataController.shared.container.viewContext, trip: Trip) {
        self.moc = context
        self.trip = trip
        loadFromMapItem(annotatedMapItem, trip)
    }
        
    func loadFromLocation(_ location: Location) {
        self.name = location.name ?? ""
        self.title = location.title ?? ""
        self.subtitle = location.subtitle ?? ""
        self.poiCategory = location.poiCategory ?? .gasStation
        self.dateLeave = location.dateLeave ?? Date()
        self.dateArrive = location.dateArrive ?? Date()
        self.overNightStop = location.overNightStop
        self.numberOfNights = location.numberOfNights
        self.locationIndex = location.locationIndex
        self.notes = location.notes ?? ""
        self.startLocation = location.startLocation
        self.latitude = location.latitude
        self.longitude = location.longitude
    }
    
    func loadFromMapItem(_ mapItem: AnnotatedMapItem, _ trip: Trip) {
        self.name = mapItem.item.name ?? ""
        self.title = mapItem.item.placemark.title ?? ""
        self.subtitle = mapItem.item.placemark.subtitle ?? ""
        self.latitude = mapItem.item.placemark.coordinate.latitude
        self.longitude = mapItem.item.placemark.coordinate.longitude
        self.poiCategory = mapItem.item.pointOfInterestCategory ?? .beach
        
        // Initialize default values for new location
        self.dateArrive = trip.startDate ?? Date()
        self.dateLeave = trip.startDate ?? Date()
        self.overNightStop = false
        self.numberOfNights = 0
        self.locationIndex = 0  // This will be set properly when saving
        self.notes = ""
        self.startLocation = false
        
        // Debug print
        print("LoadFromMapItem:")
        print("Name: \(self.name)")
        print("Title: \(self.title)")
        print("POI Category: \(self.poiCategory)")
        print("Dates: \(self.dateArrive) - \(self.dateLeave)")
    }
    
    func save() throws {
        
        print("Save started")
        if location == nil {
            // Create new location
            location = Location(context: moc)
            location?.id = UUID()
        }
        
        guard let location = location else {
            throw NSError(domain: "LocationEditModel", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Failed to create or access location"])
        }
        
        // Update all properties
        location.name = name
        location.title = title
        location.subtitle = subtitle
        location.poiCategory = poiCategory
        location.dateLeave = dateLeave
        location.dateArrive = dateArrive
        location.overNightStop = overNightStop
        location.numberOfNights = numberOfNights
        location.locationIndex = locationIndex
        location.notes = notes
        location.startLocation = startLocation
        location.latitude = latitude
        location.longitude = longitude
        
        if let trip = trip {
            trip.addToLocation(location)
        }
        
        if moc.hasChanges {
            try moc.save()
            print("Save completed")
        }
    }
}

