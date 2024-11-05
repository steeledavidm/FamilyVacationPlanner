//
//  MapInfo.swift
//  FamilyVacationPlanner
//
//  Created by David Steele on 7/8/24.
//

import Foundation
import MapKit

struct MapInfo: Identifiable {
    let id: UUID = UUID()
    let locationid: UUID
    let dateLeave: Date
    var markerLabelStart: String
    var markerLabelEnd: String
    var startingPoint: CLLocationCoordinate2D?
    var endingPoint: CLLocationCoordinate2D?
    var route: MKRoute?
    var routeColor: String?
    var polyline: MKPolyline?
    var travelTime: String?
    var travelDistance: String?
}
