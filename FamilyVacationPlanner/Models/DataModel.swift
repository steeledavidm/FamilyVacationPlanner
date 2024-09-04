//
//  DataModel.swift
//  FamilyVacationPlanner
//
//  Created by David Steele on 8/2/24.
//

import CoreData
import Foundation
import MapKit
import SwiftUI

@Observable class DataModel {
    
    let moc: NSManagedObjectContext = DataController.shared.container.viewContext
    var locations: [Location] = []
    var allMapInfo: [MapInfo] = []
    var daySegmentsForFunction: [Segment] = [Segment(segmentIndex: 0, dayDate: Date(), dayString: "", startLocation: Location(), endLocation: Location())]
    var startingPoint: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 42.0, longitude: -92.0)
    var endingPoint: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 42.0, longitude: -100.0)
    var route: MKRoute?
    var tripSegments: [DaySegments] = []
    var daySegments: [Segment] = []
    var comprehensiveAndDailySegments: [DaySegments] = []
    var currentLocation: CLLocation = CLLocation()
    var currentLocationPlacemark: CLPlacemark?
    var startLocationSet: Bool = false
    
    
    
    func fetchData(trip: Trip) {
        let request: NSFetchRequest<Location> = Location.fetchRequest()
        request.predicate = NSPredicate(format: "%@ IN trip", trip)
        do {
            locations = try moc.fetch(request)
        } catch {
        }
        setUpDailySegments(trip: trip)
        setUpTripComprehensiveView()
    }
    
    func getMapInfo(selectedTabIndex: Int) {
        print("Function 2")
        allMapInfo = []
        daySegmentsForFunction = comprehensiveAndDailySegments[selectedTabIndex].segments
        print("day Segment count: \(daySegmentsForFunction.count)")
        
        for segment in daySegmentsForFunction {
            let startLocation = CLLocationCoordinate2D(latitude: segment.startLocation.latitude, longitude: segment.startLocation.longitude)
            let endLocation = CLLocationCoordinate2D(latitude: segment.endLocation.latitude, longitude: segment.endLocation.longitude)
            let locationId = segment.endLocation.id
            let dateLeave = segment.dayDate
            guard let markerLabelStart = segment.startLocation.name else { return print("start Location name not known") }
            guard let markerLabelEnd = segment.endLocation.name else { return print("end location name not known") }
            
            allMapInfo.append(MapInfo(locationid: locationId ?? UUID(), dateLeave: dateLeave, markerLabelStart: markerLabelStart, markerLabelEnd: markerLabelEnd, startingPoint: startLocation, endingPoint: endLocation))
        }
    }
    
    func getRoute() {
        Task {
            for (index, mapInfo) in allMapInfo.enumerated() {
                startingPoint = mapInfo.startingPoint ?? CLLocationCoordinate2D()
                endingPoint = mapInfo.endingPoint  ?? CLLocationCoordinate2D()
                
                if startingPoint.longitude != endingPoint.longitude {
                    do {
                        let route = try await getDirections()
                        if index < allMapInfo.count {
                            allMapInfo[index].route = route
                        }
                    } catch {
                        print("Error fetching data : \(error.localizedDescription)")
                    }
                    
                }
            }
            allMapInfo.sort {$0.dateLeave < $1.dateLeave}
            print("allMapInfo.count: \(allMapInfo.count)")
        }
    }


    func getDirections() async throws -> MKRoute  {
        route = nil
        print("Getting Directions")
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: startingPoint))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: endingPoint))
        
        let directions = MKDirections(request: request)
        let response = try? await directions.calculate()
        route = response?.routes.first
        return route ?? MKRoute()
    }
    
    
   func setUpDailySegments(trip: Trip) {
        let calendar = Calendar.current
        var tripStartDate: Date = Date()
        var tripEndDate: Date = Date()
        var dateOfDay: Date = Date()
        var tripEndLocation: Location = Location()
        var currentLocation: Location = Location()
        
        tripStartDate = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: trip.startDate ?? Date()) ?? Date()
        //print("Midnight for startDate \(String(describing: trip.startDate)): \(tripStartDate)")
        
        tripEndDate = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: trip.endDate ?? Date()) ?? Date()
        
        let numberOfDays = (calendar.dateComponents([.day], from: tripStartDate, to: tripEndDate).day ?? 0) + 1
        //print("number of Days: \(String(describing: numberOfDays))")
        
        
        
        var dayStartLocation: Location = Location()
        var dayEndLocation: Location = Location()
        tripSegments = []
        for dayNumber in 0..<numberOfDays {
            daySegments = []
            tripSegments.append(DaySegments(dayIndex: dayNumber + 1, segments: [], comprehensive: false))
            dateOfDay = calendar.date(byAdding: DateComponents(day: dayNumber), to: tripStartDate) ?? Date()
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM-dd-yyyy"
            let formattedDateString = formatter.string(from: dateOfDay)
            startLocationSet = false
            for location in locations {
                if location.overNightStop || location.startLocation {
                    if location.startLocation {
                        if !trip.oneWay {
                            tripEndLocation = location
                        }
                    }
                    if location.dateLeave ?? Date() > dateOfDay && location.dateLeave ?? Date() < (dateOfDay + 3600 * 24) {
                        dayStartLocation = location
                        startLocationSet = true
                    }
                    if !startLocationSet {
                        dayStartLocation = currentLocation
                    }
                    if location.dateArrive ?? Date() > dateOfDay && location.dateArrive ?? Date() < (dateOfDay + 3600 * 24) {
                        dayEndLocation = location
                        currentLocation = location
                    }
                }
            }
            if dayNumber == numberOfDays - 1 {
                dayEndLocation = tripEndLocation
            }
            daySegments.append(Segment(segmentIndex: 0, dayDate: dateOfDay, dayString: formattedDateString, startLocation: dayStartLocation , endLocation: dayEndLocation ))
            tripSegments[dayNumber].segments = daySegments
            
            for location in locations {
                if location.dateArrive ?? Date() >= dateOfDay && location.dateArrive ?? Date() < (dateOfDay + 3600 * 24) {
                    if !location.overNightStop && !location.startLocation {
                        let newSegment = Segment(segmentIndex: 0, dayDate: dateOfDay, dayString: formattedDateString, startLocation: daySegments[Int(location.startIndex)].startLocation, endLocation: location)
                        
                        for (index, segment) in daySegments.enumerated() {
                            if newSegment.startLocation.id == segment.startLocation.id {
                                let originalSegment = daySegments[index]
                                daySegments[index] = newSegment
                                daySegments.insert(originalSegment, at: index + 1)
                                daySegments[index + 1].startLocation = location
                            }
                            daySegments[index].segmentIndex = index
                        }
                    }
                }
            }
            tripSegments[dayNumber].segments = daySegments
        }
    }
    
    func setUpTripComprehensiveView() {
        comprehensiveAndDailySegments = []
        var daySegmentsAccumulator: [Segment] = []
        for tripSegment in tripSegments {
            daySegmentsAccumulator = daySegmentsAccumulator + (tripSegment.segments)
        }
        let daySegmentforComprehensive: DaySegments = DaySegments(dayIndex: 0, segments: daySegmentsAccumulator, comprehensive: true)
        comprehensiveAndDailySegments.append(daySegmentforComprehensive)
        comprehensiveAndDailySegments.append(contentsOf: tripSegments)
    }
    
//    func getCurrentLocation(completionHandler: @escaping (CLPlacemark?) -> Void ) {
//        
//        locationManager.checkLocationAuthorization()
//        if let lastLocation = self.locationManager.lastKnownLocation {
//            let geocoder = CLGeocoder()
//            
//            geocoder.reverseGeocodeLocation(lastLocation, completionHandler: { (placemarks, error) in
//                if error == nil {
//                    let firstLocation = placemarks?[0]
//                    completionHandler(firstLocation)
//                }
//                else {
//                    completionHandler(nil)
//                }
//            })
//        }
//    }
    
    func getCurrentLocation(locationManager: LocationManager) async throws -> CLPlacemark {
        locationManager.checkLocationAuthorization()
        currentLocation = locationManager.lastKnownLocation ?? CLLocation()
        
        let geoCoder = CLGeocoder()
        
        guard let placemark = try await geoCoder.reverseGeocodeLocation(currentLocation).first else {
            throw CLError(.geocodeFoundPartialResult)
        }
        currentLocationPlacemark = placemark
        return placemark
    }
    
    
    func populateRecentList(trip: Trip) async throws -> [Location] {

        let request: NSFetchRequest<Location> = Location.fetchRequest()
        request.predicate = NSPredicate(format: "%@ IN trip", trip)
        do {
            locations = try moc.fetch(request)
        } catch {
        }
            
            let currentLoc = Location(context: moc)
            var recentList: [Location] = []
            currentLoc.name = "Current Location"
            currentLoc.title = currentLocationPlacemark?.name
            currentLoc.latitude = currentLocationPlacemark?.location?.coordinate.latitude ?? 0.0
            currentLoc.longitude = currentLocationPlacemark?.location?.coordinate.longitude ?? 0.0
            
            recentList.append(currentLoc)
            
            for location in locations {
                if location.overNightStop {
                    recentList.append(location)
                }
            }
            for location in locations {
                if location.startLocation {
                    recentList.append(location)
                }
            }
            
            return recentList
        
    }
    
    
    
    
    
}
