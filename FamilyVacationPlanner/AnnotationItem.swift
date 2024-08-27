//
//  AnnotationItem.swift
//  FamilyVacationPlanner
//
//  Created by David Steele on 6/20/24.
//

import Foundation
import MapKit

struct AnnotationItem: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var title: String
    var subtitle: String
    var latitude: Double
    var longitude: Double
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

