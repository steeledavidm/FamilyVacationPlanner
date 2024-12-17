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

@Observable @MainActor class DataModel {
    
    let moc: NSManagedObjectContext = DataController.shared.container.viewContext
    var locations: [Location] = []
    var allMapInfo: [MapInfo] = []
    var daySegmentsForFunction: [Segment] = []
    var results: [AnnotatedMapItem] = []
    var region: MKCoordinateRegion = MKCoordinateRegion()
    var tripSegments: [DaySegments] = []
    var currentLocation: CLLocation = CLLocation()
    var locationPlacemark: MKPlacemark?
    var startLocationSet: Bool = false
    var plotRecentItems: Bool = true
    var recentList: [Location] = []
    var mapAnnotation: AnnotatedMapItem?
    var coordinateRange: CoordinateRange?
    var mapCameraRegion: MKCoordinateRegion = MKCoordinateRegion()
    
    func getMapInfo(selectedTabIndex: Int, comprehensiveAndDailySegments: [DaySegments]) {
        print("Function 2")
        allMapInfo = []
        if comprehensiveAndDailySegments.count > selectedTabIndex {
            if let daySegments = comprehensiveAndDailySegments[selectedTabIndex].segments { //}, !daySegments.isEmpty {
                daySegmentsForFunction = daySegments
                print("day Segment count: \(daySegmentsForFunction.count)")
            } else {
                print("No segments found for the selected tab.")
            }
        } else {
            print("Invalid tab index selected.")
        }
    
        for segment in daySegmentsForFunction {
            if segment.segmentComplete && !segment.placeholder {
                let segmentStart = segment.startLocation ?? Location(context: moc)
                let startLocation = CLLocationCoordinate2D(latitude: segmentStart.latitude, longitude: segmentStart.longitude)
                let markerLabelStart = segmentStart.name ?? "Unknown Name"
                let startIcon = LocationIcon(poiCategory: segment.startLocation?.poiCategory)
                let segmentEnd = segment.endLocation ?? Location(context: moc)
                let endLocation = CLLocationCoordinate2D(latitude: segmentEnd.latitude, longitude: segmentEnd.longitude)
                let markerLabelEnd = segmentEnd.name ?? "Uknown Name"
                let endIcon = LocationIcon(poiCategory: segment.endLocation?.poiCategory)
                let route = segment.polyline
                allMapInfo.append(MapInfo(markerLabelStart: markerLabelStart, markerLabelEnd: markerLabelEnd, startingPoint: startLocation, endingPoint: endLocation, startIcon: startIcon, endIcon: endIcon, route: route))
            }
        }
    }
    
    func getCurrentLocation(locationManager: LocationManager) async throws {
        print("get current location")
        locationManager.checkLocationAuthorization()
        currentLocation = locationManager.lastKnownLocation ?? CLLocation()
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
    
    func populateRecentList(trip: Trip) async throws {
        print("populate Recent List")
        recentList = []
        let request: NSFetchRequest<Location> = Location.fetchRequest()
        request.predicate = NSPredicate(format: "%@ IN trip", trip)
        do {
            locations = try moc.fetch(request)
        } catch {
        }
        Task {
            try await getLocationPlacemark(location: currentLocation)
            let currentLoc = Location(context: moc)
            currentLoc.name = "Current Location"
            currentLoc.title = "\(locationPlacemark?.name ?? ""), \(locationPlacemark?.locality ?? ""), \(locationPlacemark?.administrativeArea ?? "")  \(locationPlacemark?.postalCode ?? "") \(locationPlacemark?.country ?? "")"
            currentLoc.latitude = locationPlacemark?.location?.coordinate.latitude ?? 0.0
            currentLoc.longitude = locationPlacemark?.location?.coordinate.longitude ?? 0.0
            trip.addToLocation(currentLoc)
            
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
            
//            results = []
//            for item in recentList {
//                try await getLocationPlacemark(location: CLLocation(latitude: item.latitude, longitude: item.longitude))
//                if let placemark = locationPlacemark {
//                    let mapItem: MKMapItem = MKMapItem(placemark: placemark)
//                    mapItem.name = item.name
//                    results.append(AnnotatedMapItem(item: mapItem))
//                    print("results: \(results.count)")
//                }
//            }
        }
    }
    
    func getPlace(from address: AddressResult) async throws {
        let request = MKLocalSearch.Request()
        let title = address.title
        let subtitle = address.subtitle
        results = []
        request.region = MKCoordinateRegion(center: mapCameraRegion.center, span: MKCoordinateSpan(latitudeDelta: 0.7, longitudeDelta: 0.7))
        print("in getPlace")
        print(request.region)
        request.naturalLanguageQuery = subtitle.contains(title)
        ? subtitle : title + ", " + subtitle
        Task {
            let search = MKLocalSearch(request: request)
            let response = try? await search.start()
            let resultsMKMapItems = response?.mapItems
            if let resultsMKMapItems = resultsMKMapItems {
                for result in resultsMKMapItems {
                    results.append(AnnotatedMapItem(item: result))
                }
            }
            print("number of results: \(results.count)")
            if results.count > 0 {
                coordinateRange = CoordinateRange(searchResults: results)
            }
            print(coordinateRange)
        }
    }
}
