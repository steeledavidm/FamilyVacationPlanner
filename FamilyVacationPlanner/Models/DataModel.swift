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
    var daySegmentsForFunction: [Segment] = []
    var startingPoint: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 42.0, longitude: -92.0)
    var endingPoint: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 42.0, longitude: -100.0)
    var mapCameraRegion: MKCoordinateRegion = MKCoordinateRegion()
    var results: [AnnotatedMapItem] = []
    var region: MKCoordinateRegion = MKCoordinateRegion()
    var route: MKRoute?
    var tripSegments: [DaySegments] = []
    var daySegments: [Segment] = []
    var comprehensiveAndDailySegments: [DaySegments] = []
    var currentLocation: CLLocation = CLLocation()
    var locationPlacemark: MKPlacemark?
    var startLocationSet: Bool = false
    var plotRecentItems: Bool = true
    var recentList: [Location] = []
    var mapAnnotation: AnnotatedMapItem?
    
    func getMapInfo(selectedTabIndex: Int, comprehensiveAndDailySegments: [DaySegments]) {
        print("Function 2")
        allMapInfo = []
        if let daySegments = comprehensiveAndDailySegments[selectedTabIndex].segments {
            daySegmentsForFunction = daySegments
            print("day Segment count: \(daySegmentsForFunction.count)")
        }
    
        for segment in daySegmentsForFunction {
            if segment.segmentComplete {
                let segmentStart = segment.startLocation ?? Location()
                let startLocation = CLLocationCoordinate2D(latitude: segmentStart.latitude, longitude: segmentStart.longitude)
                let markerLabelStart = segmentStart.name ?? "Unknown Name"
                
                let segmentEnd = segment.endLocation ?? Location()
                let endLocation = CLLocationCoordinate2D(latitude: segmentEnd.latitude, longitude: segmentEnd.longitude)
                let locationId = segmentEnd.id
                let markerLabelEnd = segmentEnd.name ?? "Uknown Name"
                
                let dateLeave = segment.dayDate
                allMapInfo.append(MapInfo(locationid: locationId ?? UUID(), dateLeave: dateLeave, markerLabelStart: markerLabelStart, markerLabelEnd: markerLabelEnd, startingPoint: startLocation, endingPoint: endLocation))
                print(allMapInfo.count)
            }
        }
    }
    
    func getRoute() {
        print("Get route")
        Task {
            for (index, mapInfo) in allMapInfo.enumerated() {
                startingPoint = mapInfo.startingPoint ?? CLLocationCoordinate2D()
                endingPoint = mapInfo.endingPoint  ?? CLLocationCoordinate2D()
                
                if startingPoint.longitude != endingPoint.longitude {
                    do {
                        let route = try await getDirections()
                        let segmentDistance = Measurement(value: route.distance, unit: UnitLength.meters)
                        let segmentTime = Measurement(value: route.expectedTravelTime, unit: UnitDuration.seconds)
                        if index < allMapInfo.count {
                            allMapInfo[index].route = route
                            allMapInfo[index].travelDistance = segmentDistance.formatted(.measurement(width: .abbreviated, usage: .road))
                            allMapInfo[index].travelTime = segmentTime.formatted()
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
    
    func getCurrentLocation(locationManager: LocationManager) async throws -> CLLocation {
        print("get current location")
        locationManager.checkLocationAuthorization()
        currentLocation = locationManager.lastKnownLocation ?? CLLocation()
        return currentLocation
    }
    
    func getLocationPlacemark(location: CLLocation) async throws {
        print("get Location Placemark")
        let geoCoder = CLGeocoder()
        
        guard let placemark = try await geoCoder.reverseGeocodeLocation(location).first else {
            throw CLError(.geocodeFoundPartialResult)
        }
        
        locationPlacemark = MKPlacemark.init(placemark: placemark)
        
        if let placemark = locationPlacemark {
            mapAnnotation = AnnotatedMapItem(item: MKMapItem(placemark: placemark))
            print(placemark.thoroughfare ?? "no street name")
        }
    }
    
    func populateRecentList(trip: Trip) async throws -> [Location] {
        print("populate Recent List")
        recentList = []
        let request: NSFetchRequest<Location> = Location.fetchRequest()
        request.predicate = NSPredicate(format: "%@ IN trip", trip)
        do {
            locations = try moc.fetch(request)
        } catch {
        }
        
        let currentLoc = Location(context: moc)
        currentLoc.name = "Current Location"
        currentLoc.title = "\(locationPlacemark?.name ?? ""), \(locationPlacemark?.locality ?? ""), \(locationPlacemark?.administrativeArea ?? "")  \(locationPlacemark?.postalCode ?? "") \(locationPlacemark?.country ?? "")"
        currentLoc.latitude = locationPlacemark?.location?.coordinate.latitude ?? 0.0
        currentLoc.longitude = locationPlacemark?.location?.coordinate.longitude ?? 0.0

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
        results = []
        for item in recentList {
            try await getLocationPlacemark(location: CLLocation(latitude: item.latitude, longitude: item.longitude))
            if let placemark = locationPlacemark {
                let mapItem: MKMapItem = MKMapItem(placemark: placemark)
                mapItem.name = item.name
                results.append(AnnotatedMapItem(item: mapItem))
                print("results: \(results.count)")
            }
        }
            return recentList
        }
    
    func saveLocation(annotationItem: AnnotationItem, startLocation: Bool, overNightStop: Bool, trip: Trip) {
        let location = Location(context: moc)
        location.id = UUID()
        location.name = annotationItem.name
        location.title = annotationItem.title
        location.subtitle = annotationItem.subtitle
        location.latitude = annotationItem.latitude
        location.longitude = annotationItem.longitude
        location.startLocation = startLocation
        location.overNightStop = overNightStop
        trip.addToLocation(location)
        try? moc.save()
    }
    
    func getPlace(from address: AddressResult) async throws {
        let request = MKLocalSearch.Request()
        let title = address.title
        let subtitle = address.subtitle
        results = []
        
        request.region = mapCameraRegion
        print("in getPlace")
        print(request.region)
        request.naturalLanguageQuery = subtitle.contains(title)
        ? subtitle : title + ", " + subtitle

        let response = try await MKLocalSearch(request: request).start()
        await MainActor.run {
            region = response.boundingRegion
            let resultsMKMapItem = response.mapItems
            for result in resultsMKMapItem {
                results.append(AnnotatedMapItem(item: result))
            }
        }
        
    }
    
    
    
    
    
}
