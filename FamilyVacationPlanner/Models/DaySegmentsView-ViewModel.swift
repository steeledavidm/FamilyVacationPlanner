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
        var tripSegments: [DaySegments] = []
        var comprehensiveAndDailySegments: [DaySegments] = []
        var tripStartLocation: Location?
        
        func fetchData(trip: Trip) async throws {
            print("Fetch Data")
            let request: NSFetchRequest<Location> = Location.fetchRequest()
            request.predicate = NSPredicate(format: "%@ IN trip", trip)
            do {
                locations = try moc.fetch(request)
            } catch {
            }
            Task {
                await setUpDailySegments(trip: trip)
                setUpTripComprehensiveView()
            }
        }
        
        func setUpDailySegments(trip: Trip) async {
            print("setUp Daily Segments")
            var tripStartDate: Date = Date()
            var dateOfDay: Date = Date()
            var tripEndLocation: Location = Location()
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
                if let segments = tripSegments[dayNumber].segments {
                    for (index, segment) in segments.enumerated() {
                        if segment.segmentComplete {
                            tripSegments[dayNumber].segments?[index].route = await getRoute(segment: segment)
                        }
                    }
                }
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
            for dayNumber in 0..<numberOfDays {
                let dateOfDay = calendar.date(byAdding: DateComponents(day: dayNumber), to: tripStartDate) ?? Date()
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM-dd-yyyy"
                let formattedDateString = formatter.string(from: dateOfDay)
                tripSegments.append(DaySegments(dayIndex: dayNumber, dayDate: dateOfDay, formattedDateString: formattedDateString, segments: segments, startLocationSet: false, endLocationSet: false, comprehensive: false))
            }
        }
         
         func setUpTripComprehensiveView() {
             print("setup Trip Comp View")
             comprehensiveAndDailySegments = []
             var daySegmentsAccumulator: [Segment] = []
             for tripSegment in tripSegments {
                 if let segments = tripSegment.segments {
                     daySegmentsAccumulator = daySegmentsAccumulator + segments
                 }
             }

             //let daySegmentforComprehensive: DaySegments = DaySegments(dayIndex: 0, formattedDateString: "", segments: daySegmentsAccumulator, startLocationSet: false, endLocationSet: false, comprehensive: true)
             //comprehensiveAndDailySegments.append(daySegmentforComprehensive)
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
            try await fetchData(trip: trip)
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
    }
}
