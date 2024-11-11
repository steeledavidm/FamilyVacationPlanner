//
//  DateArray.swift
//  FamilyVacationPlanner
//
//  Created by David Steele on 7/19/24.
//

import Foundation
import MapKit

struct DaySegments: Identifiable, Hashable {
    let id: UUID = UUID()
    var dayIndex: Int
    var dayDate: Date?
    var formattedDateString: String
    var segments: [Segment]?
    var startLocationSet: Bool
    var endLocationSet: Bool
    var comprehensive: Bool
    var totalTime: TimeInterval
    var totalDistance: CLLocationDistance
    var totalPolyline: MKPolyline?
}
