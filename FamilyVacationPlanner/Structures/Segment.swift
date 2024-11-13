//
//  Segment.swift
//  FamilyVacationPlanner
//
//  Created by David Steele on 7/15/24.
//

import Foundation
import MapKit

struct Segment: Identifiable, Hashable {
    let id: UUID = UUID()
    var segmentIndex: Int
    var dayDate: Date
    var startLocation: Location?
    var endLocation: Location?
    var placeholder: Bool = false
    var segmentComplete: Bool {
        if startLocation != nil && endLocation != nil {
            return true
        } else {
            return false
        }
    }
    var distance: CLLocationDistance? // {
//        route?.distance
//    }
    var time: TimeInterval? //{
//        route?.expectedTravelTime
//    }
    var polyline: MKPolyline? //{
//        route?.polyline
//    }
}
