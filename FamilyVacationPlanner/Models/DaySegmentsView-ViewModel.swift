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
    @Observable @MainActor class ViewModel {
        let moc: NSManagedObjectContext = DataController.shared.container.viewContext
        let routeManager: RouteManager = RouteManager()
        var locations: [Location] = []
        var trip: Trip?
        var tripSegments: [DaySegments] = []
        var comprehensiveAndDailySegments: [DaySegments] = []
        var daySummary: [Segment] = []
        var tripStartLocation: Location?
        
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
                        tripSegments[dayNumber].segments?[0] = Segment(segmentIndex: 0, dayDate: dateOfDay,  startLocation: dayStartLocation, placeholder: true, tripID: trip.id!)
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
             routeManager.cleanCache(tripID: trip, activeSegments: daySegmentsAccumulator, tripDeleted: false)
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
        }
        
        func removeSegment(at offsets: IndexSet) {
            print("Delete initiated")
        }
        
        func combineRoutes(routes: [CachedRoute]) -> MKPolyline {
            let allCoordinates = routes.flatMap { $0.points.map { $0.coordinate } }
            return MKPolyline(coordinates: allCoordinates, count: allCoordinates.count)
        }
    }
}
