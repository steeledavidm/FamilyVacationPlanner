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
    
    var trip: Trip?
    var tripStartLocation: Location?
    let routeManager: RouteManager = RouteManager()
    var comprehensiveAndDailySegments: [DaySegments] = []
    
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
        coordinateRange = CoordinateRange(segments: daySegmentsForFunction, currentLocation: currentLocation)
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
        
        // Simplify query for global chains
        request.naturalLanguageQuery = address.title
        
        // Use a wider region for global searches
        request.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: coordinateRange?.focusLatitude ?? 100, longitude: coordinateRange?.focusLongitude ?? 100),
            span: MKCoordinateSpan(latitudeDelta: coordinateRange?.spanLat ?? 1.0, longitudeDelta: coordinateRange?.spanLon ?? 1.0)
        )
        print(request.region)
        
        let search = MKLocalSearch(request: request)
        let response = try await search.start()
        
        results = response.mapItems.map { AnnotatedMapItem(item: $0) }
        
        if !results.isEmpty {
            coordinateRange = CoordinateRange(searchResults: results)
        }
        
        print("Number of results: \(results.count)")
    }
    
    func setup(trip: Trip) {
        self.trip = trip
    }
    
    func updateLocations() async {
        guard let trip = trip else { return }
        await setUpDailySegments(trip: trip)
        setUpTripComprehensiveView(trip: trip)
    }
    
    func setUpDailySegments(trip: Trip) async {
        print("setUp Daily Segments")
        var tripStartDate: Date = Date()
        var dateOfDay: Date = Date()
        var tripEndLocation: Location = Location(context: moc)
        var dayStartLocation: Location?
        var dayEndLocation: Location?
        var overNightStaysAccumulator: Int = 0
        var overNightStayLocation: Location?
        
        tripSegments = []
        // intialize based on number of days in trip
        setupTripArray(trip: trip)
        tripStartDate = tripSegments[0].segments?[0].dayDate ?? Date()
        let numberOfDays = tripSegments.count
        
        // cycle through each day to set up segments
        for dayNumber in 0..<numberOfDays {
            let calendar = Calendar.current
            dateOfDay = calendar.date(byAdding: DateComponents(day: dayNumber), to: tripStartDate) ?? Date()
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM-dd-yyyy"
            //group locations for trip by day
            var locationsForDay: [Location] = []
            for location in locations {
                if Int(location.locationIndex) < (dayNumber + 1) * 100 && Int(location.locationIndex) >= dayNumber * 100 {
                    locationsForDay.append(location)
                }
                locationsForDay.sort {
                    $0.locationIndex < $1.locationIndex
                }
            }
            // loop over each location for the day
            for location in locationsForDay {
                if location.locationIndex == 0 {
                    tripStartLocation = location
                    if !trip.oneWay {
                        tripEndLocation = location
                    }
                }
                //check if location is start location for the day
                if location.locationIndex == dayNumber * 100 {
                    dayStartLocation = location
                    // set first segment for the day to have start location
                    tripSegments[dayNumber].segments?[0] = Segment(segmentIndex: 0, dayDate: dateOfDay,  startLocation: dayStartLocation, placeholder: false, tripID: trip.id!)
                    tripSegments[dayNumber].startLocationSet = true
                } else {
                    // know that location is either a end location or a point of interest
                    // turn off placeholder for initial segment
                    tripSegments[dayNumber].segments?[0].placeholder = false
                    if let daySegmentsCount = tripSegments[dayNumber].segments?.count {
                        // store last segment endLocation
                        let previousEndLocation = tripSegments[dayNumber].segments?.last?.endLocation
                        // save the location as end location for the last segment in the list
                        tripSegments[dayNumber].segments?[daySegmentsCount - 1].endLocation = location
                        // if the location is not a endLocation then there is another segment and the start location is the previous end location
                        if location.locationIndex != dayNumber * 100 + 99 {
                            tripSegments[dayNumber].segments?.append(Segment(segmentIndex: daySegmentsCount, dayDate: dateOfDay, startLocation: location, endLocation: previousEndLocation, tripID: trip.id!))
                        } else {
                            // location must be an endLocation for the day
                            dayEndLocation = location
                            overNightStaysAccumulator = Int(dayEndLocation?.numberOfNights ?? 0)
                            overNightStayLocation = dayEndLocation
                            // set endLocationSet for the current day
                            tripSegments[dayNumber].endLocationSet = true
                            // fill out dayEndLocation for next days in same location.
                            while overNightStaysAccumulator >= 0 {
                                for day in dayNumber..<numberOfDays {
                                    print("day: \(day), numberOfDays: \(numberOfDays)")
                                    if day + 1 < numberOfDays {
                                        tripSegments[day + 1].segments?[0].startLocation = overNightStayLocation
                                        tripSegments[day + 1].startLocationSet = true
                                        overNightStaysAccumulator -= 1
                                        if overNightStaysAccumulator >= 0 {
                                            let numberOfSegments = tripSegments[day + 1].segments?.count
                                            tripSegments[day + 1].segments?[(numberOfSegments ?? 1) - 1].endLocation = overNightStayLocation
                                            tripSegments[day + 1].endLocationSet = true
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            if !trip.oneWay {
                if let lastDayLastSegment = (tripSegments[numberOfDays - 1].segments?.count) {
                    tripSegments[numberOfDays - 1].segments?[lastDayLastSegment - 1].endLocation = tripEndLocation
                }
            }
            
            
            // if segment is complete get route information
            var completeRouteForDay: [CachedRoute] = []
            if let segments = tripSegments[dayNumber].segments {
                for (index, segment) in segments.enumerated() {
                    if segment.segmentComplete && !segment.placeholder {
                        let route = await routeManager.fetchAndCacheRoute(segment: segment)
                        tripSegments[dayNumber].segments?[index].time = route?.time
                        tripSegments[dayNumber].segments?[index].distance = route?.distance
                        tripSegments[dayNumber].segments?[index].polyline = route?.toMKPolyline()
                        if let route = route {
                            completeRouteForDay.append(route)
                        }
                    }
                }
                var totalTime: TimeInterval = 0
                var totalDistance: CLLocationDistance = 0
                for route in completeRouteForDay {
                    totalTime += route.time
                    totalDistance += route.distance
                }
                tripSegments[dayNumber].totalTime = totalTime
                tripSegments[dayNumber].totalDistance = totalDistance
                tripSegments[dayNumber].totalPolyline = combineRoutes(routes: completeRouteForDay)
            }
            print("dayNumber: \(dayNumber)")
        }
        
        if numberOfDays > 1 {
            for dayNumber in 0..<numberOfDays {
                print("number of segments: \(tripSegments[dayNumber].segments?.count ?? 999)")
                if let daySegmentsCount = tripSegments[dayNumber].segments?.count {
                    tripSegments[dayNumber].segments?.append(Segment(segmentIndex: daySegmentsCount, dayDate: dateOfDay, startLocation: tripStartLocation, endLocation: tripEndLocation, placeholder: true, tripID: trip.id!))
                }
            }
        }
     }
    
    func setupTripArray(trip: Trip) {
        let calendar = Calendar.current
        let tripStartDate = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: trip.startDate ?? Date()) ?? Date()
        let tripEndDate = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: trip.endDate ?? Date()) ?? Date()
        let numberOfDays = (calendar.dateComponents([.day], from: tripStartDate, to: tripEndDate).day ?? 0) + 1
        let segments: [Segment] = [Segment(segmentIndex: 0, dayDate: Date(), tripID: trip.id!)]
        for dayNumber in 1..<(numberOfDays + 1) {
            let dateOfDay = calendar.date(byAdding: DateComponents(day: dayNumber), to: tripStartDate) ?? Date()
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM-dd-yyyy"
            let formattedDateString = formatter.string(from: dateOfDay)
            let totalTime = 0
            let totalDistance = 0
            tripSegments.append(DaySegments(dayIndex: dayNumber, dayDate: dateOfDay, formattedDateString: formattedDateString, segments: segments, startLocationSet: false, endLocationSet: false, comprehensive: false, totalTime: TimeInterval(totalTime), totalDistance: CLLocationDistance(totalDistance)))
        }
    }
     
    func setUpTripComprehensiveView(trip: Trip) {
         print("setup Trip Comp View")
         comprehensiveAndDailySegments = []
         var daySegmentsAccumulator: [Segment] = []
         var totalTime: TimeInterval = 0
         var totalDistance: CLLocationDistance = 0
         for tripSegment in tripSegments {
             daySegmentsAccumulator.append(Segment(segmentIndex: tripSegment.dayIndex, dayDate: tripSegment.dayDate ?? Date(), startLocation: tripSegment.segments?.first?.startLocation, endLocation: tripSegment.segments?[(tripSegment.segments?.count ?? 1) - 1].endLocation, placeholder: false, distance: tripSegment.totalDistance, time: tripSegment.totalTime, polyline: tripSegment.totalPolyline, tripID: trip.id!))
             totalTime += tripSegment.totalTime
             totalDistance += tripSegment.totalDistance
         }
         let daySegmentforComprehensive: DaySegments = DaySegments(dayIndex: 0, formattedDateString: "Trip Overview", segments: daySegmentsAccumulator, startLocationSet: true, endLocationSet: true, comprehensive: true, totalTime: totalTime, totalDistance: totalDistance)
         comprehensiveAndDailySegments.append(daySegmentforComprehensive)
         comprehensiveAndDailySegments.append(contentsOf: tripSegments)
        routeManager.cleanCache(trip: trip, activeSegments: daySegmentsAccumulator, tripDeleted: false)
     }
    
    func combineRoutes(routes: [CachedRoute]) -> MKPolyline {
        let allCoordinates = routes.flatMap { $0.points.map { $0.coordinate } }
        return MKPolyline(coordinates: allCoordinates, count: allCoordinates.count)
    }
}

