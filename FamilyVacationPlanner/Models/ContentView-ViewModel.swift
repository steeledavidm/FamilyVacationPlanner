//
//  ContentView-ViewModel.swift
//  FamilyVacationPlanner
//
//  Created by David Steele on 8/27/24.
//

import CoreData
import Foundation
import MapKit
import SwiftUI

extension ContentView {
    @Observable class ViewModel {
        
        var dataModel = DataModel()
        var singleLocation = false
        
        @MainActor func updateMapCameraPosition(selectedTabIndex: Int, selectedDetent: PresentationDetent, currentLocation: CLLocation) -> MapCameraPosition {
            
            if !dataModel.comprehensiveAndDailySegments.isEmpty {
                dataModel.daySegmentsForFunction = dataModel.comprehensiveAndDailySegments[selectedTabIndex].segments
                dataModel.getMapInfo()
                if dataModel.comprehensiveAndDailySegments[selectedTabIndex].segments[0].startLocation == dataModel.comprehensiveAndDailySegments[selectedTabIndex].segments[0].endLocation {
                    singleLocation = true
                } else {
                    singleLocation = false
                }
            }
            
            let selectedDetent: PresentationDetent = selectedDetent
            var position: MapCameraPosition
            
            let screenWidth = UIScreen.main.bounds.width
            let screenHeight = UIScreen.main.bounds.height
            
            var allMapInfo = dataModel.allMapInfo
            let currentLatitude: Double = currentLocation.coordinate.latitude
            let currentLongitude: Double = currentLocation.coordinate.longitude
            var plotCurrentLocation = false
                
            if allMapInfo.count == 0 {
                plotCurrentLocation.toggle()
                allMapInfo.append(MapInfo(locationid: UUID(), dateLeave: Date(), markerLabelStart: "", markerLabelEnd: "", startingPoint: CLLocationCoordinate2D(latitude: currentLatitude, longitude: currentLongitude), endingPoint: CLLocationCoordinate2D(latitude: currentLatitude, longitude: currentLongitude)))
                
                print(allMapInfo[0].endingPoint?.latitude ?? 99)
                print(allMapInfo[0].startingPoint?.longitude ?? 99)
                print(allMapInfo[0].endingPoint?.latitude ?? 99)
                print(allMapInfo[0].startingPoint?.longitude ?? 99)
            }
        
            // Calculate the bounding box for all annotations
            let latitudesEndPoint = allMapInfo.map { $0.endingPoint!.latitude}
            let latitudesStartPoint = allMapInfo.map { $0.startingPoint!.latitude}
            let latitudes: [CLLocationDegrees] = latitudesEndPoint + latitudesStartPoint
            let longitudesEndPoint = allMapInfo.map { $0.endingPoint!.longitude}
            let longitudesStartPoint = allMapInfo.map { $0.startingPoint!.longitude}
            let longitudes: [CLLocationDegrees] = longitudesEndPoint + longitudesStartPoint
            
            let minLat = latitudes.min()!
            let maxLat = latitudes.max()!
            let minLon = longitudes.min()!
            let maxLon = longitudes.max()!
            
            // Calculate the span
            let spanLat = (maxLat - minLat)
            let spanLon = (maxLon - minLon)
            
            // Calculate the center of the bounding box
            let centerLat = (minLat + maxLat) / 2
            let centerLon = (minLon + maxLon) / 2
            
            var adjustedCenterLat = centerLat
            var adjustedSpanLon = spanLon * 1.5
            var adjustedSpanLat = spanLat * 1.5
            
            if spanLon >= spanLat {
                let screenSpanLat = spanLon * screenHeight/screenWidth
                adjustedCenterLat = centerLat - screenSpanLat / 2 * 0.4
            }
            
            if spanLon < spanLat {
                adjustedCenterLat = centerLat - spanLat / 2
                adjustedSpanLon = spanLon / 0.4
                adjustedSpanLat = spanLat / 0.4
            }
            if selectedDetent == .fraction(0.5) {
                
                position = .region(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: adjustedCenterLat, longitude: centerLon), span: MKCoordinateSpan(latitudeDelta: adjustedSpanLat, longitudeDelta: adjustedSpanLon)))
                if singleLocation {
                    position = .region(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: adjustedCenterLat - 0.03/4, longitude: centerLon), span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)))
                }
            } else {
                position = .automatic
                if singleLocation {
                    position = .region(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: adjustedCenterLat, longitude: centerLon), span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)))
                }
            }
            if plotCurrentLocation {
                position = .region(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: adjustedCenterLat - 50/4, longitude: centerLon), span: MKCoordinateSpan(latitudeDelta:25, longitudeDelta: 25)))
            }
            return position
        }
    }
}
