//
//  DateArray.swift
//  FamilyVacationPlanner
//
//  Created by David Steele on 7/19/24.
//

import Foundation

struct DaySegments: Identifiable, Hashable {
    let id: UUID = UUID()
    var dayIndex: Int
    var segments: [Segment]
    var comprehensive: Bool
}
