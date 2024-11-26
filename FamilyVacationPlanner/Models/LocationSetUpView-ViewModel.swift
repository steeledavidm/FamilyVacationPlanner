//
//  LocationSetUpView-ViewModel.swift
//  FamilyVacationPlanner
//
//  Created by David Steele on 9/27/24.
//

import CoreData
import Foundation

extension LocationSetUpView {

    @Observable class ViewModel {
        var dayFromDayIndex: Date = Date()
        var numberOfNightsLeft: Int = 0

        func getLocationIndex(startLocation: Bool, overNightStop: Bool, dayIndex: Int, locationIndex: Int) -> Int16 {
            print("dayIndex: \(dayIndex)")
            print("locationIndex: \(locationIndex)")
            var newLocationIndex: Int16 = 0
            if startLocation {
                newLocationIndex = Int16(dayIndex) * Int16(100)
            }
            
            if locationIndex > 0  {
                newLocationIndex = Int16(dayIndex) * Int16(100) + Int16(locationIndex)
            }
            
            if overNightStop {
                newLocationIndex = Int16(dayIndex) * Int16(100) + Int16(99)
            }
            return newLocationIndex
        }
        
        func getDates(trip: Trip, dayIndex: Int) {
            
            let calendar = Calendar.current
            let tripStartDate = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: trip.startDate ?? Date()) ?? Date()
            let finalDate = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: trip.endDate ?? Date()) ?? Date()
            
            dayFromDayIndex = tripStartDate + TimeInterval(dayIndex * 60 * 60 * 24)
            numberOfNightsLeft = (calendar.dateComponents([.day], from: dayFromDayIndex, to: finalDate).day ?? 0)
        }
    }
}

