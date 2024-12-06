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
    var distance: CLLocationDistance?
    var time: TimeInterval?
    var polyline: MKPolyline?
    var tripID: UUID
    
    var segmentComplete: Bool {
        if startLocation != nil && endLocation != nil {
            return true
        } else {
            return false
        }
    }
    
    var poiIconStart: LocationIcon {
        LocationIcon(poiCategory: startLocation?.poiCategory)
    }
    var poiIconEnd: LocationIcon {
        LocationIcon(poiCategory: endLocation?.poiCategory)
    }
    var segmentRouteIdentifier: Double {
        if let startLocation = startLocation {
            if let endLocation = endLocation {
                return startLocation.latitude + startLocation.longitude + endLocation.latitude + endLocation.longitude
            }
        }
        return 0
    }

}
