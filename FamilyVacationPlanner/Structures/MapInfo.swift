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
    var markerLabelStart: String
    var markerLabelEnd: String
    var startingPoint: CLLocationCoordinate2D?
    var endingPoint: CLLocationCoordinate2D?
    var startIcon: LocationIcon?
    var endIcon: LocationIcon?
    var route: MKPolyline?
    var routeColor: String?
    var polyline: MKPolyline?
}
