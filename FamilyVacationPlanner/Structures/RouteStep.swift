//
//  RouteStep.swift
//  FamilyVacationPlanner
//
//  Created by David Steele on 12/5/24.
//

import Foundation
import MapKit

struct RouteStep: Codable {
    let instructions: String
    let distance: Double
    let points: [RoutePoint]
    
    init(from mkStep: MKRoute.Step) {
        self.instructions = mkStep.instructions
        self.distance = mkStep.distance
        
        var points: [RoutePoint] = []
        let polyPoints = mkStep.polyline.points()
        let pointCount = mkStep.polyline.pointCount
        
        for i in 0..<pointCount {
            let point = polyPoints[i]
            let coords = point.coordinate
            points.append(RoutePoint(coordinate: coords))
        }
        
        self.points = points
    }
}
