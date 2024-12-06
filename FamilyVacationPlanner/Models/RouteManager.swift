//
//  RouteManager.swift
//  FamilyVacationPlanner
//
//  Created by David Steele on 12/5/24.
//

import Foundation
import MapKit

@Observable
class RouteManager {
    private let cacheManager = RouteCacheManager.shared
    
    func fetchAndCacheRoute(segment: Segment) async -> CachedRoute? {
        // Check cache first
        if cacheManager.doesCacheExist(for: segment.segmentRouteIdentifier) {
            do {
                let cachedRoute = try cacheManager.loadCachedRoute(withIdentifier: segment.segmentRouteIdentifier)
                // Check if cache is recent
                if Date().timeIntervalSince(cachedRoute.lastUpdated) < 3600 {
                    // Convert cached route to MKRoute equivalent
                    // Convert cached data immediately
                    // Still fetch fresh data in background
                    Task {
                        try? await fetchFreshRoute(segment: segment)
                    }
                    return cachedRoute
                }
            } catch {
                print("Error loading cached route: \(error)")
            }
        }
        return try? await fetchFreshRoute(segment: segment)
    }
    
    func fetchFreshRoute(segment: Segment) async throws -> CachedRoute {
        print("Getting Directions")
        let request = MKDirections.Request()
        let startingPoint = CLLocationCoordinate2D(latitude: segment.startLocation?.latitude ?? 0, longitude: segment.startLocation?.longitude ?? 0)
        let endingPoint = CLLocationCoordinate2D(latitude: segment.endLocation?.latitude ?? 0, longitude: segment.endLocation?.longitude ?? 0)
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: startingPoint))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: endingPoint))
        
        let directions = MKDirections(request: request)
        do {
            let response = try await directions.calculate()
            guard let route = response.routes.first else {
                throw NSError(domain: "RouteManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "No route found"])
            }
            
            // Cache the new route
            try cacheManager.cacheRoute(route, withIdentifier: segment.segmentRouteIdentifier, trip: segment.tripID)
            
            return CachedRoute(from: route, identifier: segment.segmentRouteIdentifier, trip: segment.tripID)
        } catch {
            throw error
        }
    }
    
    func cleanCache(tripID: Trip, activeSegments: [Segment], tripDeleted: Bool) {
        cacheManager.showContents()
    }
}
