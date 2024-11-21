//
//  GlobalVariables.swift
//  FamilyVacationPlanner
//
//  Created by David Steele on 7/12/24.
//

import Foundation
import MapKit
import SwiftUI

@Observable

class GlobalVariables {
    var selectedTrip: Trip?
    var displaySearchedLocations: Bool = false
    var locationFromMap: AnnotationItem?
    var locationType: LocationType?
    var selectedDetent: PresentationDetent = .fraction(0.5)
    var selectedTabIndex: Int = 0
    var showSearchLocationSheet: Bool = false
    var markerSelected: Bool = false
    var locationIndex: Int = 0
    var comprehensiveAndDailySegments: [DaySegments] = []
    
    func selectTrip(_ trip: Trip) {
        selectedTrip = trip
    }
}
