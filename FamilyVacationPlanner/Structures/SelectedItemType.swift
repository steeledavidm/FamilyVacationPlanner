//
//  SelectedItemType.swift
//  FamilyVacationPlanner
//
//  Created by David Steele on 12/10/24.
//

import Foundation
import MapKit
import SwiftUI

enum SelectedItemType: Equatable {
    case existing(MapSelection<AnnotatedMapItem>)
    case new(CLLocation)
}
