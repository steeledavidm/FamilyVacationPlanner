//
//  CachedRoute.swift
//  FamilyVacationPlanner
//
//  Created by David Steele on 12/5/24.
//

import Foundation
import MapKit

struct CachedRoute: Codable {
    let identifier: Double
    let lastUpdated: Date
    let name: String?
    let points: [RoutePoint]
    let steps: [RouteStep]
    let distance: Double
    let time: Double
    let tripID: UUID

    init(from route: MKRoute, identifier: Double, trip: UUID ) {
        self.identifier = identifier
        self.lastUpdated = Date()
        self.name = route.name
        self.distance = route.distance
        self.time = route.expectedTravelTime
        self.tripID = trip
        
        var routePoints: [RoutePoint] = []
        let polyPoints = route.polyline.points()
        let pointCount = route.polyline.pointCount
        
        for i in 0..<pointCount {
            let point = polyPoints[i]
            let coords = point.coordinate
            routePoints.append(RoutePoint(coordinate: coords))
        }
        self.points = routePoints
        
        self.steps = route.steps.map {RouteStep(from: $0)}
            
    }
    func toMKPolyline() -> MKPolyline {
        var coordinates = points.map { $0.coordinate}
        return MKPolyline(coordinates: &coordinates, count: points.count)
    }
}




