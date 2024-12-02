//
//  TripSetUpView-ViewModel.swift
//  FamilyVacationPlanner
//
//  Created by David Steele on 11/16/24.
//

import CoreData
import Foundation

extension TripSetUpView {


    @Observable @MainActor class ViewModel {
        let moc: NSManagedObjectContext = DataController.shared.container.viewContext
        
        func generateMockData() {
            let tripFetchRequest: NSFetchRequest<Trip> = Trip.fetchRequest()
            let trips = try! moc.fetch(tripFetchRequest)
            for (tripIndex, trip) in trips.enumerated() {
                print("let mockTrip\(tripIndex) = Trip(context: moc)")
                print("mockTrip\(tripIndex).startDate = dateFormatter.date(from: \"\(String(describing: trip.startDate))\")")
                print("mockTrip\(tripIndex).endDate = dateFormatter.date(from: \"\(String(describing: trip.endDate))\")")
                print("mockTrip\(tripIndex).tripName = \"\(trip.tripName ?? "")\"")
                print("mockTrip\(tripIndex).oneWay = \(String(describing: trip.oneWay))")
                print("")
                
                let locationsFetchRequest: NSFetchRequest<Location> = Location.fetchRequest()
                locationsFetchRequest.predicate = NSPredicate(format: "%@ in trip", trip)
                let locations = try! moc.fetch(locationsFetchRequest)
                var locationsList = ""
                locationsList = (0..<locations.count).map {
                    "mockLocation\(tripIndex)\($0)"
                    }
                    .joined(separator: ", ")
                print("mockTrip\(tripIndex).location = [\(locationsList)]")
                
                for (locationIndex, location) in locations.enumerated() {
                    print("let mockLocation\(tripIndex)\(locationIndex) = Location(context: moc)")
                    print("mockLocation\(tripIndex)\(locationIndex).dateArrive = dateFormatter.date(from: \"\(String(describing: location.dateArrive))\")")
                    print("mockLocation\(tripIndex)\(locationIndex).dateLeave = dateFormatter.date(from: \"\(String(describing: location.dateLeave))\")")
                    print("mockLocation\(tripIndex)\(locationIndex).latitude = \(location.latitude)")
                    print("mockLocation\(tripIndex)\(locationIndex).locationIndex = \(location.locationIndex)")
                    print("mockLocation\(tripIndex)\(locationIndex).longitude = \(location.longitude)")
                    print("mockLocation\(tripIndex)\(locationIndex).modified = \(String(describing: location.modified))")
                    print("mockLocation\(tripIndex)\(locationIndex).name = \"\(location.name ?? "")\"")
                    print("mockLocation\(tripIndex)\(locationIndex).notes = \"\(location.notes ?? "")\"")
                    print("mockLocation\(tripIndex)\(locationIndex).numberOfNights = \(location.numberOfNights)")
                    print("mockLocation\(tripIndex)\(locationIndex).overNightStop = \(String(describing: location.overNightStop))")
                    print("mockLocation\(tripIndex)\(locationIndex).primary = \(String(describing: location.primary))")
                    print("mockLocation\(tripIndex)\(locationIndex).requester = \"\(location.requester ?? "")\"")
                    print("mockLocation\(tripIndex)\(locationIndex).startLocation = \(String(describing: location.startLocation))")
                    print("mockLocation\(tripIndex)\(locationIndex).status = \"\(location.status ?? "")\"")
                    print("mockLocation\(tripIndex)\(locationIndex).subtitle = \"\(location.subtitle ?? "")\"")
                    print("mockLocation\(tripIndex)\(locationIndex).title = \"\(location.title ?? "")\"")
                    print("")
                    
                }
            }
            
        }
    }
}
