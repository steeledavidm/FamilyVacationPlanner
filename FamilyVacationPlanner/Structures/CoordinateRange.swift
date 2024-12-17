//
//  CoordinateRange.swift
//  FamilyVacationPlanner
//
//  Created by David Steele on 12/16/24.
//

import Foundation
import MapKit
import SwiftUI

struct CoordinateRange: Hashable {
    var focusLatitude: Double
    var focusLongitude: Double
    var spanLat: Double
    var spanLon: Double
    let minSpan: Double = 0.05
    
    init(selectedLocation: LocationSetUp) {
        self.focusLatitude = selectedLocation.latitude
        self.focusLongitude = selectedLocation.longitude
        self.spanLat = minSpan
        self.spanLon = minSpan
    }
    
    init(location: Location) {
        self.focusLatitude = location.latitude
        self.focusLongitude = location.longitude
        self.spanLat = minSpan
        self.spanLon = minSpan
    }
    
    init(searchResults: [AnnotatedMapItem]) {
        var latitudes: [Double] = []
        var longitudes: [Double] = []
        if searchResults.count == 1 {
            self.spanLat = minSpan
            self.spanLon = minSpan
            self.focusLatitude = searchResults[0].item.placemark.coordinate.latitude
            self.focusLongitude = searchResults[0].item.placemark.coordinate.longitude
        } else {
            for item in searchResults {
                latitudes.append(item.item.placemark.coordinate.latitude)
                longitudes.append(item.item.placemark.coordinate.longitude)
            }
            let maxLat = latitudes.max() ?? 100
            let maxLon = longitudes.max() ?? 100
            let minLat = latitudes.min() ?? 100
            let minLon = longitudes.min() ?? 100
            self.spanLat = maxLat - minLat
            self.spanLon = maxLon - minLon
            self.focusLatitude = (spanLat)/2 + minLat
            self.focusLongitude = (spanLon)/2 + minLon
        }
    }
    
    init(segments: [Segment]) {
        var latitudes: [Double] = []
        var longitudes: [Double] = []
        if segments.count == 1 && segments[0].startLocation == segments[0].endLocation {
            self.spanLat = minSpan
            self.spanLon = minSpan
            self.focusLatitude = segments[0].startLocation?.latitude ?? 100
            self.focusLongitude = segments[0].startLocation?.longitude ?? 100
        } else {
            for segment in segments {
                if segment.segmentComplete {
                    latitudes.append(segment.startLocation?.latitude ?? 100)
                    latitudes.append(segment.endLocation?.latitude ?? 100)
                    longitudes.append(segment.startLocation?.longitude ?? 100)
                    longitudes.append(segment.endLocation?.longitude ?? 100)
                }
            }
            let maxLat = latitudes.max() ?? 100
            let maxLon = longitudes.max() ?? 100
            let minLat = latitudes.min() ?? 100
            let minLon = longitudes.min() ?? 100
            self.spanLat = maxLat - minLat
            self.spanLon = maxLon - minLon
            self.focusLatitude = (spanLat)/2 + minLat
            self.focusLongitude = (spanLon)/2 + minLon
        }
    }
}
