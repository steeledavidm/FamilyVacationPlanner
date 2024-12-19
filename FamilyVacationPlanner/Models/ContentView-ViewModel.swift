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
    }
}
    


