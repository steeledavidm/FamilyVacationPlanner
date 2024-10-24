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
        var position: MapCameraPosition = .automatic
        var singleLocation = false
        var selectedTabIndex: Int
        var selectedDetent: PresentationDetent
        
        init(selectedTabIndex: Int, selectedDetent: PresentationDetent) {
            self.selectedTabIndex = selectedTabIndex
            self.selectedDetent = selectedDetent
        }

        func updateMapCameraPosition(currentLocation: CLLocation, dataModel: DataModel, globalVars: GlobalVariables) {
            print("Function 3")
            let screenWidth = UIScreen.main.bounds.width
            let screenHeight = UIScreen.main.bounds.height
            var allMapInfo = dataModel.allMapInfo
            let currentLatitude: Double = currentLocation.coordinate.latitude
            let currentLongitude: Double = currentLocation.coordinate.longitude
            var plotCurrentLocation = false
            print(allMapInfo.count)
            if !dataModel.comprehensiveAndDailySegments.isEmpty {
                if dataModel.comprehensiveAndDailySegments[selectedTabIndex].segments?[0].startLocation == dataModel.comprehensiveAndDailySegments[selectedTabIndex].segments?[0].endLocation {
                    singleLocation = true
                } else {
                    singleLocation = false
                }
            }
            
            if globalVars.locationFromMap != nil {
                print("filling MapInfo")
                let locationfromMap = globalVars.locationFromMap
                allMapInfo = []
                allMapInfo.append(MapInfo(locationid: UUID(), dateLeave: Date(), markerLabelStart: "", markerLabelEnd: "", startingPoint: CLLocationCoordinate2D(latitude: locationfromMap?.latitude ?? 0.0 , longitude: locationfromMap?.longitude ?? 0.0), endingPoint: CLLocationCoordinate2D(latitude: locationfromMap?.latitude ?? 0.0 , longitude: locationfromMap?.longitude ?? 0.0)))
            }

            print("allMapInfo: \(String(describing: allMapInfo.count))")
                
            if allMapInfo.count == 0 {
                plotCurrentLocation = true
                allMapInfo.append(MapInfo(locationid: UUID(), dateLeave: Date(), markerLabelStart: "", markerLabelEnd: "", startingPoint: CLLocationCoordinate2D(latitude: currentLatitude, longitude: currentLongitude), endingPoint: CLLocationCoordinate2D(latitude: currentLatitude, longitude: currentLongitude)))
                print(currentLocation)
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
            var positionSetter = 0
            if selectedDetent == .fraction(0.1)  {
                position = .automatic
                positionSetter = 1
                if singleLocation {
                    position = .region(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon), span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)))
                        positionSetter = 2
                    }
                } else {
                    position = .region(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: adjustedCenterLat, longitude: centerLon), span: MKCoordinateSpan(latitudeDelta: adjustedSpanLat, longitudeDelta: adjustedSpanLon)))
                    positionSetter = 3
                    if singleLocation {
                        position = .region(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: centerLat - 0.005/2, longitude: centerLon), span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)))
                        positionSetter = 4
                    }

                }
            if plotCurrentLocation || allMapInfo.count == 1 {
                    position = .region(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: adjustedCenterLat - 10/2, longitude: centerLon), span: MKCoordinateSpan(latitudeDelta: 10, longitudeDelta: 10)))
                positionSetter = 5
                }
            if globalVars.showSearchLocationSheet && dataModel.plotRecentItems {
                position = .region(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: centerLat - 0.005/2, longitude: centerLon), span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)))
                positionSetter = 6
            }
            print("positionSetter: \(positionSetter)")
            print(position)
            }
        }
    }
    


