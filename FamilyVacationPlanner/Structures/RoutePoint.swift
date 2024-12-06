//
//  RoutePoint.swift
//  FamilyVacationPlanner
//
//  Created by David Steele on 12/5/24.
//

import Foundation
import MapKit

struct RoutePoint: Codable {
    let latitude: Double
    let longitude: Double
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    init(coordinate: CLLocationCoordinate2D) {
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
    }
}
