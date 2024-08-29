//
//  GlobalVariables.swift
//  FamilyVacationPlanner
//
//  Created by David Steele on 7/12/24.
//

import Foundation
import SwiftUI
@Observable

class GlobalVariables {
    var currentLocation: Location = Location()
    var selectedTabIndex: Int = 0
    var selectedDetent: PresentationDetent = .fraction(0.5)
}
