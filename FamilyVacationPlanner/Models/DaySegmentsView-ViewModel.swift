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
    }
}
