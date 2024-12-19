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
            self.spanLat = .maximum(abs(maxLat - minLat), minSpan)
            self.spanLon = .maximum(abs(maxLon - minLon), minSpan)
            self.focusLatitude = (maxLat - minLat)/2 + minLat
            self.focusLongitude = (maxLon - minLon)/2 + minLon
        }
    }
    
    init(segments: [Segment]) {
        var latitudes: [Double] = []
        var longitudes: [Double] = []
        var envelope: PolyLineEnvelope = PolyLineEnvelope(NEPointCoordinate: CLLocationCoordinate2D(latitude: 100, longitude: 100), SWPointCoordinate: CLLocationCoordinate2D(latitude: 100, longitude: 100))
        if segments.count == 1 && segments[0].startLocation == segments[0].endLocation {
            self.spanLat = minSpan
            self.spanLon = minSpan
            self.focusLatitude = segments[0].startLocation?.latitude ?? 100
            self.focusLongitude = segments[0].startLocation?.longitude ?? 100
        } else {
            print("************* Segments ***************")
            for segment in segments {
                if segment.segmentComplete && !segment.placeholder {
                    envelope = getPolyLineEnvelope(polyline: segment.polyline ?? MKPolyline())
                    latitudes.append(envelope.NEPointCoordinate.latitude)
                    latitudes.append(envelope.SWPointCoordinate.latitude)
                    longitudes.append(envelope.NEPointCoordinate.longitude)
                    longitudes.append(envelope.SWPointCoordinate.longitude)
                }
            }
            let maxLat = latitudes.max() ?? 100
            let maxLon = longitudes.max() ?? 100
            let minLat = latitudes.min() ?? 100
            let minLon = longitudes.min() ?? 100
            self.spanLat = .maximum(abs(maxLat - minLat), minSpan)
            self.spanLon = .maximum(abs(maxLon - minLon), minSpan)
            self.focusLatitude = (maxLat - minLat)/2 + minLat
            self.focusLongitude = (maxLon - minLon)/2 + minLon
        }
    }
}

struct PolyLineEnvelope {
    let NEPointCoordinate: CLLocationCoordinate2D
    let SWPointCoordinate: CLLocationCoordinate2D
}


func getPolyLineEnvelope(polyline: MKPolyline) -> (PolyLineEnvelope) {
    let boundingRect = polyline.boundingMapRect
    
    let NEPoint = MKMapPoint(x: boundingRect.maxX, y: boundingRect.maxY)
    let NEPointCoordinate = NEPoint.coordinate
    let SWPoint = MKMapPoint(x: boundingRect.minX, y: boundingRect.minY)
    let SWPointCoordinate = SWPoint.coordinate
    
    print("NEPointCoordinate: \(NEPointCoordinate)")
    print("SWPointCoordinate: \(SWPointCoordinate)")
    return PolyLineEnvelope(NEPointCoordinate: NEPointCoordinate, SWPointCoordinate: SWPointCoordinate)
}
