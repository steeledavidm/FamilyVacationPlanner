//
//  LocationExtension.swift
//  FamilyVacationPlanner
//
//  Created by David Steele on 11/18/24.
//

import CoreData
import MapKit
import SwiftUI

extension Location {
    // Computed property to convert between MKPointOfInterestCategory and String
    var poiCategory: MKPointOfInterestCategory? {
        get {
            guard let rawValue = categoryRawValue else { return nil }
            return MKPointOfInterestCategory(rawValue: rawValue)
        }
        set {
            categoryRawValue = newValue?.rawValue
        }
    }
    
    // Helper method to set the category directly from an MKMapItem
    func setCategory(from mapItem: MKMapItem) {
        self.poiCategory = mapItem.pointOfInterestCategory
    }
}
