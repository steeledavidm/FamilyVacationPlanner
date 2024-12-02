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
    @Observable @MainActor class ViewModel {
        var position: MapCameraPosition = .automatic
        
        func updateMapCameraPosition(dataModel: DataModel, globalVars: GlobalVariables) {
            print("Function 3")
            let selectedDetent: PresentationDetent = globalVars.selectedDetent
            let screenWidth = UIScreen.main.bounds.width
            let screenHeight = UIScreen.main.bounds.height
            var allMapInfo = dataModel.allMapInfo
            let currentLocation = dataModel.currentLocation
            let currentLatitude: Double = currentLocation.coordinate.latitude
            let currentLongitude: Double = currentLocation.coordinate.longitude
            var plotCurrentLocation = false
            var singleLocation: Bool = false
            
            print(allMapInfo.count)
            if !globalVars.comprehensiveAndDailySegments.isEmpty {
                print("I'm here")
                if globalVars.comprehensiveAndDailySegments[globalVars.selectedTabIndex].segments?[0].startLocation == globalVars.comprehensiveAndDailySegments[globalVars.selectedTabIndex].segments?[0].endLocation {
                    singleLocation = true
                    print("single location = true")
                } else {
                    singleLocation = false
                    print("single location = false")
                }
            }
            
            if globalVars.locationFromMap != nil {
                print("filling MapInfo")
                let locationfromMap = globalVars.locationFromMap
                allMapInfo = []
                allMapInfo.append(MapInfo(markerLabelStart: "", markerLabelEnd: "", startingPoint: CLLocationCoordinate2D(latitude: locationfromMap?.latitude ?? 0.0 , longitude: locationfromMap?.longitude ?? 0.0), endingPoint: CLLocationCoordinate2D(latitude: locationfromMap?.latitude ?? 0.0 , longitude: locationfromMap?.longitude ?? 0.0)))
            }
            
            print("allMapInfo: \(String(describing: allMapInfo.count))")
            var seedAllMapInfo = false
            if allMapInfo.count == 0 {
                plotCurrentLocation = true
                //Check if start location is set and if so use that location else use currentLocation.
                if !globalVars.comprehensiveAndDailySegments.isEmpty {
                    if globalVars.comprehensiveAndDailySegments[globalVars.selectedTabIndex].startLocationSet {
                        let startLocation = globalVars.comprehensiveAndDailySegments[globalVars.selectedTabIndex].segments?[0].startLocation
                        allMapInfo.append(MapInfo(markerLabelStart: "", markerLabelEnd: "", startingPoint: CLLocationCoordinate2D(latitude: startLocation?.latitude ?? currentLatitude, longitude: startLocation?.longitude ?? currentLongitude), endingPoint: CLLocationCoordinate2D(latitude: startLocation?.latitude ?? currentLatitude, longitude: startLocation?.longitude ?? currentLongitude) ))
                        print(currentLocation)
                    } else {
                        seedAllMapInfo = true
                    }
                } else {
                    seedAllMapInfo = true
                }
            }
            if seedAllMapInfo {
                allMapInfo.append(MapInfo(markerLabelStart: "", markerLabelEnd: "", startingPoint: CLLocationCoordinate2D(latitude: currentLatitude, longitude: currentLongitude), endingPoint: CLLocationCoordinate2D(latitude: currentLatitude, longitude: currentLongitude)))
            }
            
            
            // Calculate the bounding box for all annotations
            let latitudesEndPoint = allMapInfo.map { Double($0.endingPoint?.latitude ?? 0)}
            let latitudesStartPoint = allMapInfo.map { Double($0.startingPoint?.latitude ?? 0)}
            let latitudes = latitudesEndPoint + latitudesStartPoint
            let longitudesEndPoint = allMapInfo.map { Double($0.endingPoint?.longitude ?? 0)}
            let longitudesStartPoint = allMapInfo.map { Double($0.startingPoint?.longitude ?? 0)}
            let longitudes = longitudesEndPoint + longitudesStartPoint
            
            let minLat = latitudes.min()
            let maxLat = latitudes.max()
            let minLon = longitudes.min()
            let maxLon = longitudes.max()
            
            // Calculate the span
            var spanLat = (maxLat! - minLat!)
            var spanLon = (maxLon! - minLon!)
            
            // Calculate the center of the bounding box
            var centerLat = (minLat! + maxLat!) / 2
            var centerLon = (minLon! + maxLon!) / 2
            print("plot RecentItems: \(dataModel.plotRecentItems)")
            if globalVars.showSearchLocationSheet && !dataModel.plotRecentItems && !globalVars.markerSelected {
                print("using dataModel.region")
                allMapInfo = []
                plotCurrentLocation = false
                singleLocation = false
                centerLat = dataModel.region.center.latitude
                centerLon = dataModel.region.center.longitude
                spanLat = dataModel.region.span.latitudeDelta
                spanLon = dataModel.region.span.longitudeDelta
            }
            
            var adjustedCenterLat = centerLat
            var adjustedSpanLon = spanLon * 1.5
            var adjustedSpanLat = spanLat * 1.5
            
            if spanLon >= spanLat {
                let screenSpanLat = spanLon * screenHeight/screenWidth
                adjustedCenterLat = centerLat - screenSpanLat / 2 * 0.6
            }
            if spanLon < spanLat {
                adjustedCenterLat = centerLat - spanLat / 1.5
                adjustedSpanLon = spanLon / 0.4
                adjustedSpanLat = spanLat / 0.4
            }
            print("selectedDetent: \(selectedDetent)")
            print("singleLocation: \(singleLocation)")
            print("plotCurrentLocation: \(plotCurrentLocation)")
            print("allMapInfoCount: \(allMapInfo.count)")
            print("showSearchSheet: \(globalVars.showSearchLocationSheet)")
            print("plotRecentItems: \(dataModel.plotRecentItems)")
            print("marker Selected: \(globalVars.markerSelected)")
            
            if plotCurrentLocation  || allMapInfo.count == 0 || singleLocation {
                singleLocation = true
            } else {
                singleLocation = false
            }
            
            
            enum Span: Double {
                case wideSpan = 0.1
                case narrowSpan = 0.005
                
                var value: Double {
                    return self.rawValue
                }
            }
            var span: Span
            
            if singleLocation {
                span = .narrowSpan
            } else {
                span = .wideSpan
            }
            
            let centerLatAdjustmentForDetent = span.value/2
            var lat: Double = 0
            var lon: Double = 0
            var latDelta: Double = 0
            var lonDelta: Double = 0
            
            if selectedDetent == .fraction(0.12) && !singleLocation {
                position = .automatic
                return
            }
            
            if selectedDetent == .fraction(0.12) && singleLocation {
                lat = centerLat
                lon = centerLon
                latDelta = span.value
                lonDelta = span.value
            }
            
            if selectedDetent != .fraction(0.12) && !singleLocation {
                lat = adjustedCenterLat
                lon = centerLon
                latDelta = adjustedSpanLat
                lonDelta = adjustedSpanLon
            }
            
            if selectedDetent != .fraction(0.12) && singleLocation {
                lat = centerLat - centerLatAdjustmentForDetent
                lon = centerLon
                latDelta = span.value
                lonDelta = span.value
            }
            position = .region(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: lat, longitude: lon), span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)))

        }
    }
}
    


