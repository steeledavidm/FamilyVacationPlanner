//
//  RouteCacheManager.swift
//  FamilyVacationPlanner
//
//  Created by David Steele on 12/5/24.
//

import Foundation
import MapKit

class RouteCacheManager {
    static let shared = RouteCacheManager()
    private let fileManager = FileManager.default
    
    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private let cacheFolder = "RoutesCache"
    
    private init() {
        createCacheFolderIfNeeded()
    }
    
    func cacheRoute(_ route: MKRoute, withIdentifier segment: Segment, trip: UUID) throws {
        let cachedRoute = CachedRoute(from: route, identifier: segment.segmentRouteIdentifier, trip: trip)
        let cacheURL = getCacheURL(for: segment)
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(cachedRoute)
        try data.write(to: cacheURL)
        
    }
    
    func loadCachedRoute(withIdentifier segment: Segment) throws -> CachedRoute {
        let cacheURL = getCacheURL(for: segment)
        let data = try Data(contentsOf: cacheURL)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let cachedRoute = try decoder.decode(CachedRoute.self, from: data)
        
        return cachedRoute
    }
    
    func doesCacheExist(for segment: Segment) -> Bool {
        let cacheURL = getCacheURL(for: segment)
        return fileManager.fileExists(atPath: cacheURL.path)
    }
    
    func deleteCache(for segment: Segment) throws {
        let cacheURL = getCacheURL(for: segment)
        if fileManager.fileExists(atPath: cacheURL.path) {
            try fileManager.removeItem(at: cacheURL)
        }
    }
    
    func removeTripFromCache(trip: UUID) throws {
        let cacheURL = documentsDirectory.appendingPathComponent(cacheFolder).appendingPathComponent("\(trip.uuidString)")
        if fileManager.fileExists(atPath: cacheURL.path) {
            try fileManager.removeItem(at: cacheURL)
        }
    }
    
    func cleanCachedRoutes(trip: UUID, segment: Segment) {
        let cacheURL = documentsDirectory.appendingPathComponent(cacheFolder).appendingPathComponent("\(trip.uuidString)")
        do {
            let cachedSegments = try FileManager.default.contentsOfDirectory(at: cacheURL, includingPropertiesForKeys: [.isDirectoryKey], options: [])
            for cachedSegment in cachedSegments {
                let fileName = cachedSegment.lastPathComponent
                
                if String(segment.segmentRouteIdentifier).contains(fileName) {
                    try FileManager.default.removeItem(atPath: fileName)
                    print("Deleted: \(fileName)")
                }
            }
        } catch {
            print("Error deleting files: \(error)")
        }
    }
    
    func showContents() {
        let folderURL = documentsDirectory.appendingPathComponent(cacheFolder)
        print(fileManager.subpaths(atPath: folderURL.path) ?? "no files found")
    }
    
    func createTripFolder(trip: UUID) {
        let url = documentsDirectory.appendingPathComponent(cacheFolder).appendingPathComponent("\(trip.uuidString)")
        if !fileManager.fileExists(atPath: url.path) {
            try? fileManager.createDirectory(at: url, withIntermediateDirectories: true)
            print("created: \(url.path)")
        }
        print("folder exists: \(fileManager.fileExists(atPath: url.path))")
    }
    
    private func createCacheFolderIfNeeded() {
        let folderURL = documentsDirectory.appendingPathComponent(cacheFolder)
        
        if !fileManager.fileExists(atPath: folderURL.path) {
            try? fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true)
        }
    }
    
    private func getCacheURL(for segment: Segment) -> URL {
        let url = documentsDirectory
            .appendingPathComponent(cacheFolder)
            .appendingPathComponent("\(segment.tripID.uuidString)")
            .appendingPathComponent("\(segment.segmentRouteIdentifier).json")
        print("getCacheURL \(url.path)")
        return url
    }
}
