//
//  DaySegmentsView-ViewModel.swift
//  FamilyVacationPlanner
//
//  Created by David Steele on 9/16/24.
//

import CoreData
import Foundation
import MapKit
import SwiftUI

extension DaySegmentsView {
    @Observable class ViewModel {
        let moc: NSManagedObjectContext = DataController.shared.container.viewContext
        var locations: [Location] = []
        var trip: Trip?
        var tripSegments: [DaySegments] = []
        var comprehensiveAndDailySegments: [DaySegments] = []
        var daySummary: [Segment] = []
        var tripStartLocation: Location?
        
        func setup(trip: Trip) {
            self.trip = trip
        }
        
        func updateLocations(_ newLocations: [Location]) async {
            guard let trip = trip else { return }
            locations = newLocations
            await setUpDailySegments(trip: trip)
            setUpTripComprehensiveView()
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
                        tripSegments[dayNumber].segments?[0] = Segment(segmentIndex: 0, dayDate: dateOfDay,  startLocation: dayStartLocation, placeholder: true)
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
                                tripSegments[dayNumber].segments?.append(Segment(segmentIndex: daySegmentsCount, dayDate: dateOfDay, startLocation: location, endLocation: previousEndLocation))
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
                var completeRouteForDay: [MKRoute] = []
                if let segments = tripSegments[dayNumber].segments {
                    for (index, segment) in segments.enumerated() {
                        if segment.segmentComplete && !segment.placeholder {
                            let route = await getRoute(segment: segment)
                            tripSegments[dayNumber].segments?[index].time = route.expectedTravelTime
                            tripSegments[dayNumber].segments?[index].distance = route.distance
                            tripSegments[dayNumber].segments?[index].polyline = route.polyline
                            completeRouteForDay.append(route)
                        }
                    }
                    var totalTime: TimeInterval = 0
                    var totalDistance: CLLocationDistance = 0
                    for route in completeRouteForDay {
                        totalTime += route.expectedTravelTime
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
                        tripSegments[dayNumber].segments?.append(Segment(segmentIndex: daySegmentsCount, dayDate: dateOfDay, startLocation: tripStartLocation, endLocation: tripEndLocation, placeholder: true))
                    }
                }
            }
         }
        
        func setupTripArray(trip: Trip) {
            let calendar = Calendar.current
            let tripStartDate = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: trip.startDate ?? Date()) ?? Date()
            let tripEndDate = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: trip.endDate ?? Date()) ?? Date()
            let numberOfDays = (calendar.dateComponents([.day], from: tripStartDate, to: tripEndDate).day ?? 0) + 1
            let segments: [Segment] = [Segment(segmentIndex: 0, dayDate: Date())]
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
         
         func setUpTripComprehensiveView() {
             print("setup Trip Comp View")
             comprehensiveAndDailySegments = []
             var daySegmentsAccumulator: [Segment] = []
             var totalTime: TimeInterval = 0
             var totalDistance: CLLocationDistance = 0
             for tripSegment in tripSegments {
                 daySegmentsAccumulator.append(Segment(segmentIndex: tripSegment.dayIndex, dayDate: tripSegment.dayDate ?? Date(), startLocation: tripSegment.segments?.first?.startLocation, endLocation: tripSegment.segments?[(tripSegment.segments?.count ?? 1) - 1].endLocation, placeholder: false, distance: tripSegment.totalDistance, time: tripSegment.totalTime, polyline: tripSegment.totalPolyline))
                 totalTime += tripSegment.totalTime
                 totalDistance += tripSegment.totalDistance
             }
             let daySegmentforComprehensive: DaySegments = DaySegments(dayIndex: 0, formattedDateString: "Trip Overview", segments: daySegmentsAccumulator, startLocationSet: true, endLocationSet: true, comprehensive: true, totalTime: totalTime, totalDistance: totalDistance)
             comprehensiveAndDailySegments.append(daySegmentforComprehensive)
             comprehensiveAndDailySegments.append(contentsOf: tripSegments)
         }
        
        func saveLocationIndex(segments: [Segment], dayIndex: Int, trip: Trip) async throws {
            for (index, segment) in segments.enumerated() {
                print(index, segment.endLocation?.name ?? "", segment.segmentIndex)
                if let location = segment.endLocation {
                    if !location.overNightStop && !location.startLocation {
                        location.locationIndex = Int16(dayIndex) * Int16(100) + Int16(index + 1)
                        try moc.save()
                    }
                }
            }
            //try await fetchData(trip: trip)
        }
        
        func removeSegment(at offsets: IndexSet) {
            print("Delete initiated")
        }
        
        func getRoute(segment: Segment) async -> MKRoute {
            print("Get route")
            var route: MKRoute?
            do {
                let startingPoint = CLLocationCoordinate2D(latitude: segment.startLocation?.latitude ?? 0, longitude: segment.startLocation?.longitude ?? 0)
                let endingPoint = CLLocationCoordinate2D(latitude: segment.endLocation?.latitude ?? 0, longitude: segment.endLocation?.longitude ?? 0)
                
                if startingPoint.longitude != endingPoint.longitude {
                    print("Getting Directions")
                    let request = MKDirections.Request()
                    request.source = MKMapItem(placemark: MKPlacemark(coordinate: startingPoint))
                    request.destination = MKMapItem(placemark: MKPlacemark(coordinate: endingPoint))
                    
                    let directions = MKDirections(request: request)
                    let response = try await directions.calculate()
                    route = response.routes.first
                }
            } catch {
                print("Error calculating route: \(error.localizedDescription)")
            }
            print("route calculated")
            return route ?? MKRoute()
        }
        
        func combineRoutes(routes: [MKRoute]) -> MKPolyline {
            var allCoordinates: [CLLocationCoordinate2D] = []
            for route in routes {
                var coordinates: [CLLocationCoordinate2D] = []
                let pointCount = route.polyline.pointCount
                coordinates = Array(UnsafeMutableBufferPointer(start: UnsafeMutablePointer<CLLocationCoordinate2D>.allocate(capacity: pointCount), count: pointCount))
                route.polyline.getCoordinates(&coordinates, range: NSRange(location: 0, length: pointCount))
                allCoordinates.append(contentsOf: coordinates)
            }
            
            // Create a new polyline from all coordinates
            let combinedRoute = MKPolyline(coordinates: allCoordinates, count: allCoordinates.count)
            return combinedRoute
            
        }
    }
}
