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
        var sheetDetent: PresentationDetent = PresentationDetent.fraction(0.5)
        var selectedLocation: LocationSetUp?
        var safeAreaTop: CGFloat = 0.0
        
        func cameraPosition(coordinateRange: CoordinateRange) {
            let screenWidth = UIScreen.main.bounds.width
            let screenHeight = UIScreen.main.bounds.height
            let paddingPoints = 40.0
            var centerLatAdjustment: Double = 0.0
            var newCenterLat = 0.0
            var newSpanLat = 0.0
            var newSpanLon = 0.0
            var detent = 0.0
            var topLatitude: Double = 0.0
            var bottomLatitude: Double = 0.0
            
            if sheetDetent == PresentationDetent.fraction(0.12) {
                detent = 0.12
            } else {
                detent = 0.5
            }
            
            //Screen Points
            let adjustedScreenCenter = (((screenHeight - safeAreaTop) * detent) - safeAreaTop) / 2
            let adjustedScreenHeight = screenHeight - ((screenHeight - safeAreaTop) * detent) - safeAreaTop - 2 * paddingPoints
            let adjustedScreenWidth = screenWidth - 2 * paddingPoints
            
            //Screen size ratios
            let screenWidthDivHeight = adjustedScreenWidth/adjustedScreenHeight
            let coordinateSpanLonDivLat = coordinateRange.spanLon / coordinateRange.spanLat
            
            // Check if horzontal span of coordinateRange is more then screen ratio.
            if coordinateSpanLonDivLat >= screenWidthDivHeight || coordinateSpanLonDivLat == 1 {
                print("Wider than Tall")
                // If true only need to shift the coordinate range vertically for detent changes
                centerLatAdjustment = (adjustedScreenCenter * coordinateRange.spanLon / screenWidthDivHeight) / screenHeight
                newCenterLat = coordinateRange.focusLatitude - 2 * centerLatAdjustment
                newSpanLon = coordinateRange.spanLon * screenWidth / adjustedScreenWidth
                //newSpanLat = coordinateRange.spanLat * screenHeight / adjustedScreenHeight
                } else {
                    print("Taller than Wide")
                    topLatitude = (coordinateRange.focusLatitude + coordinateRange.spanLat/2) + (safeAreaTop + paddingPoints) * coordinateRange.spanLat / adjustedScreenHeight
                    bottomLatitude = (coordinateRange.focusLatitude - coordinateRange.spanLat/2) - ((screenHeight - safeAreaTop) * detent + paddingPoints) * coordinateRange.spanLat / adjustedScreenHeight
                    newSpanLat = topLatitude - bottomLatitude
                    newCenterLat = (topLatitude + bottomLatitude) / 2
                    
//                    centerLatAdjustment = coordinateRange.spanLat / screenHeight * adjustedScreenCenter
//                    newCenterLat = coordinateRange.focusLatitude - centerLatAdjustment
//                    newSpanLat = coordinateRange.spanLat * screenHeight / adjustedScreenHeight
                    //newSpanLon = newSpanLat * coordinateSpanLonDivLat
                }
                
            position = .region(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: newCenterLat, longitude: coordinateRange.focusLongitude), span: MKCoordinateSpan(latitudeDelta: newSpanLat, longitudeDelta: newSpanLon)))
            print(position)
            
            print("topLatitude: \(topLatitude)")
            print("bottomLatitude: \(bottomLatitude)")
            print("coordinateRangeLat: \(coordinateRange.focusLatitude)")
            print("coordinateRangeLon: \(coordinateRange.focusLongitude)")
            print("coordinateRangeSpanLat: \(coordinateRange.spanLat)")
            print("coordinateRangeSpanLon: \(coordinateRange.spanLon)")
            print("adjustedScreenCenter: \(adjustedScreenCenter)")
            print("screenHeight: \(screenHeight)")
            print("adjustedScreenHeight: \(adjustedScreenHeight)")
            print("screenWidth: \(screenWidth)")
            print("adjustedScreenWidth: \(adjustedScreenWidth)")
            print("screenWidthDivHeigth: \(screenWidthDivHeight)")
            print("coordinateSpanLonDivLat: \(coordinateSpanLonDivLat)")
            print("centerLatAdjustment: \(centerLatAdjustment)")
            print("newCenterLat: \(newCenterLat)")
            print("newSpanLat: \(newSpanLat)")
            
        }
        
        
        func updateMapCameraPositionOld(dataModel: DataModel, globalVars: GlobalVariables) {
            print("Function 3")
            let selectedDetent: PresentationDetent = globalVars.selectedDetent
            let screenWidth = UIScreen.main.bounds.width
            let screenHeight = UIScreen.main.bounds.height
            var allMapInfo = dataModel.allMapInfo
            let locationFromMap = globalVars.locationFromMap
            let locationFromMapLat: Double = locationFromMap?.coordinate.latitude ?? 0.0
            let locationFromMapLon: Double = locationFromMap?.coordinate.longitude ?? 0.0
            let currentLocation = dataModel.currentLocation
            let currentLocationLat: Double = currentLocation.coordinate.latitude
            let currentLocationLon: Double = currentLocation.coordinate.longitude
            var plotCurrentLocation = false
            var singleLocation: Bool = false
            
            print(allMapInfo.count)
            // force tab index 0 (comprehensive view) to be treated as multiple locations
            if globalVars.selectedTabIndex == 0 {
                singleLocation = false
            } else {
                if !globalVars.comprehensiveAndDailySegments.isEmpty {
                    print("I'm here")
                    if globalVars.comprehensiveAndDailySegments[globalVars.selectedTabIndex].segments?[0].startLocation == globalVars.comprehensiveAndDailySegments[globalVars.selectedTabIndex].segments?[0].endLocation || dataModel.results.count == 1 {
                        singleLocation = true
                        print("single location = true")
                    } else {
                        singleLocation = false
                        print("single location = false")
                    }
                }
            }
            
            if locationFromMap != nil {
                print("filling MapInfo")
                plotCurrentLocation = true
                singleLocation = true
                allMapInfo = []
                allMapInfo.append(MapInfo(markerLabelStart: "", markerLabelEnd: "", startingPoint: CLLocationCoordinate2D(latitude: locationFromMapLat , longitude: locationFromMapLon), endingPoint: CLLocationCoordinate2D(latitude: locationFromMapLat, longitude: locationFromMapLon)))
            }
            
            print("allMapInfo: \(String(describing: allMapInfo.count))")
            var seedAllMapInfo = false
            if allMapInfo.count == 0 {
                plotCurrentLocation = true
                //Check if start location is set and if so use that location else use currentLocation.
                if !globalVars.comprehensiveAndDailySegments.isEmpty {
                    if globalVars.comprehensiveAndDailySegments[globalVars.selectedTabIndex].startLocationSet {
                        let startLocation = globalVars.comprehensiveAndDailySegments[globalVars.selectedTabIndex].segments?[0].startLocation
                        allMapInfo.append(MapInfo(markerLabelStart: "", markerLabelEnd: "", startingPoint: CLLocationCoordinate2D(latitude: startLocation?.latitude ?? 0.0, longitude: startLocation?.longitude ?? 0.0), endingPoint: CLLocationCoordinate2D(latitude: startLocation?.latitude ?? 0.0, longitude: startLocation?.longitude ?? 0.0) ))
                    } else {
                        seedAllMapInfo = true
                    }
                } else {
                    seedAllMapInfo = true
                }
            }
            if seedAllMapInfo {
                allMapInfo.append(MapInfo(markerLabelStart: "", markerLabelEnd: "", startingPoint: CLLocationCoordinate2D(latitude: currentLocationLat, longitude: currentLocationLon), endingPoint: CLLocationCoordinate2D(latitude: currentLocationLat, longitude: currentLocationLon)))
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
            var adjustedSpanLon = spanLon
            var adjustedSpanLat = spanLat
            
            if spanLon >= spanLat {
                let screenSpanLat = spanLon * screenHeight/screenWidth
                adjustedCenterLat = centerLat - (screenSpanLat / 2) * 0.5
                adjustedSpanLon = spanLon * 1.5
                adjustedSpanLat = spanLat * 1.5
            }
            if spanLon < spanLat {
                adjustedCenterLat = centerLat - (spanLat / 2)
                adjustedSpanLon = spanLon / 0.5
                adjustedSpanLat = spanLat / 0.5
            }
            print("selectedDetent: \(selectedDetent)")
            print("singleLocation: \(singleLocation)")
            print("plotCurrentLocation: \(plotCurrentLocation)")
            print("allMapInfoCount: \(allMapInfo.count)")
            print("showSearchSheet: \(globalVars.showSearchLocationSheet)")
            print("plotRecentItems: \(dataModel.plotRecentItems)")
            print("marker Selected: \(globalVars.markerSelected)")
            
            if plotCurrentLocation || singleLocation {
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
                lat = centerLat
                lon = centerLon
                latDelta = adjustedSpanLat
                lonDelta = adjustedSpanLon
                
                //position = .automatic
                //return
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
            print(position)
        }
    }
}
    


