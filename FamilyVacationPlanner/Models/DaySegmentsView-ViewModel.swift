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
        
        func fetchData(trip: Trip) {
            print("Fetch Data")
            let request: NSFetchRequest<Location> = Location.fetchRequest()
            request.predicate = NSPredicate(format: "%@ IN trip", trip)
            do {
                locations = try moc.fetch(request)
            } catch {
            }
            setUpDailySegments(trip: trip)
            setUpTripComprehensiveView()
        }
        
        func setUpDailySegments(trip: Trip) {
            print("setUp Daily Segments")
            var tripStartDate: Date = Date()
            var dateOfDay: Date = Date()
            var tripEndLocation: Location = Location()
            var dayStartLocation: Location?
            var dayEndLocation: Location?
            var overNightStaysAccumulator: Int = 0
            var overNightStayLocation: Location?
            
            tripSegments = []
            setupTripArray(trip: trip)
            tripStartDate = tripSegments[0].segments?[0].dayDate ?? Date()
            let numberOfDays = tripSegments.count
            
            for dayNumber in 0..<numberOfDays {
                let calendar = Calendar.current
                dateOfDay = calendar.date(byAdding: DateComponents(day: dayNumber), to: tripStartDate) ?? Date()
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM-dd-yyyy"
                var locationsForDay: [Location] = []
                for location in locations {
                    if Int(location.locationIndex) < (dayNumber + 1) * 100 && Int(location.locationIndex) >= dayNumber * 100 {
                        locationsForDay.append(location)
                    }
                    locationsForDay.sort {
                        $0.locationIndex < $1.locationIndex
                    }
                }
                for location in locationsForDay {
                    if location.locationIndex == 0 {
                        tripStartLocation = location
                        if !trip.oneWay {
                            tripEndLocation = location
                        }
                    }
                    if location.locationIndex == dayNumber * 100 { //location is start location
                        dayStartLocation = location
                        tripSegments[dayNumber].segments?[0] = Segment(segmentIndex: 0, dayDate: dateOfDay,  startLocation: dayStartLocation)
                        tripSegments[dayNumber].startLocationSet = true
                    } else {
                        if let daySegmentsCount = tripSegments[dayNumber].segments?.count {
                            let previousEndLocation = tripSegments[dayNumber].segments?.last?.endLocation
                            tripSegments[dayNumber].segments?[daySegmentsCount - 1].endLocation = location
                            if location.locationIndex != dayNumber * 100 + 99 {
                                tripSegments[dayNumber].segments?.append(Segment(segmentIndex: daySegmentsCount, dayDate: dateOfDay, startLocation: location, endLocation: previousEndLocation))
                            } else {
                                dayEndLocation = location
                                overNightStaysAccumulator = Int(dayEndLocation?.numberOfNights ?? 0)
                                overNightStayLocation = dayEndLocation
                                tripSegments[dayNumber].endLocationSet = true
                                while overNightStaysAccumulator >= 0 {
                                    for day in dayNumber..<numberOfDays {
                                        if day + 1 < numberOfDays {
                                            tripSegments[day + 1].segments?[0].startLocation = overNightStayLocation
                                            tripSegments[day + 1].startLocationSet = true
                                            overNightStaysAccumulator -= 1
                                            if overNightStaysAccumulator >= 0 {
                                                let numberOfSegments = tripSegments[day + 1].segments?.count
                                                tripSegments[day + 1].segments?[(numberOfSegments ?? 1) - 1].endLocation = overNightStayLocation
                                            }
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
            
            for dayNumber in 0..<numberOfDays {
                if let daySegmentsCount = tripSegments[dayNumber].segments?.count {
                    tripSegments[dayNumber].segments?.append(Segment(segmentIndex: daySegmentsCount, dayDate: dateOfDay, startLocation: tripStartLocation, endLocation: tripEndLocation, placeholder: true))
                }
            }
            
            for tripSegment in tripSegments {
                if let segments = tripSegment.segments {
                    for segment in segments {
                        print("\(segment.segmentIndex) \(String(describing: segment.startLocation?.name)) \(String(describing: segment.endLocation?.name))")
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

             let daySegmentforComprehensive: DaySegments = DaySegments(dayIndex: 0, formattedDateString: "", segments: daySegmentsAccumulator, startLocationSet: false, endLocationSet: false, comprehensive: true)
             //comprehensiveAndDailySegments.append(daySegmentforComprehensive)
             comprehensiveAndDailySegments.append(contentsOf: tripSegments)
         }
    }
}
