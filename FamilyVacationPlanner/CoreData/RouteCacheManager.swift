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
    
    func cacheRoute(_ route: MKRoute, withIdentifier identifier: Double, trip: UUID) throws {
        let cachedRoute = CachedRoute(from: route, identifier: identifier, trip: trip)
        let cacheURL = getCacheURL(for: identifier)
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(cachedRoute)
        try data.write(to: cacheURL)
        
    }
    
    func loadCachedRoute(withIdentifier identifier: Double) throws -> CachedRoute {
        let cacheURL = getCacheURL(for: identifier)
        let data = try Data(contentsOf: cacheURL)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let cachedRoute = try decoder.decode(CachedRoute.self, from: data)
        
        return cachedRoute
    }
    
    func doesCacheExist(for identifier: Double) -> Bool {
        let cacheURL = getCacheURL(for: identifier)
        return fileManager.fileExists(atPath: cacheURL.path)
    }
    
    func deleteCache(for identifier: Double) throws {
        let cacheURL = getCacheURL(for: identifier)
        if fileManager.fileExists(atPath: cacheURL.path) {
            try fileManager.removeItem(at: cacheURL)
        }
    }
    
    func showContents() {
        let folderURL = documentsDirectory.appendingPathComponent(cacheFolder)
        print(fileManager.subpaths(atPath: folderURL.path) ?? "no files found")
    }
    
    private func createCacheFolderIfNeeded() {
        let folderURL = documentsDirectory.appendingPathComponent(cacheFolder)
        
        if !fileManager.fileExists(atPath: folderURL.path) {
            try? fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true)
        }
    }
    
    private func getCacheURL(for identifier: Double) -> URL {
        documentsDirectory
            .appendingPathComponent(cacheFolder)
            .appendingPathComponent("\(identifier).json")
    }
}
