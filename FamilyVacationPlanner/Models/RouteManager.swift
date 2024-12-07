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
        
        // Create folder for trip if needed
        cacheManager.createTripFolder(trip: segment.tripID)
        // Check cache
        if cacheManager.doesCacheExist(for: segment) {
            print("Cache exists for \(segment.tripID.hashValue).\(segment.segmentRouteIdentifier)")
            do {
                let cachedRoute = try cacheManager.loadCachedRoute(withIdentifier: segment)
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
        print("Cache does not exist for \(segment.tripID.hashValue).\(segment.segmentRouteIdentifier)")
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
            try cacheManager.cacheRoute(route, withIdentifier: segment, trip: segment.tripID)
            
            return CachedRoute(from: route, identifier: segment.segmentRouteIdentifier, trip: segment.tripID)
        } catch {
            throw error
        }
    }
    
    func cleanCache(trip: Trip, activeSegments: [Segment]? = nil, tripDeleted: Bool) {
        if let tripID = trip.id{
            if tripDeleted {
                try? cacheManager.removeTripFromCache(trip: tripID)
            } else {
                guard let segments = activeSegments else { return }
                for segment in segments{
                    cacheManager.cleanCachedRoutes(trip: tripID, segment: segment)
                }
            }
        }
        cacheManager.showContents()
    }
}
