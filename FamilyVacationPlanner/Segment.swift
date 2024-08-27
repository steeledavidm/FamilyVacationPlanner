//
//  Segment.swift
//  FamilyVacationPlanner
//
//  Created by David Steele on 7/15/24.
//

import Foundation

struct Segment: Identifiable, Hashable {
    let id: UUID = UUID()
    var dayDate: Date
    var dayString: String
    var startLocation: Location
    var endLocation: Location
}
