//
//  ContentView.swift
//  FamilyVacationPlanner
//
//  Created by David Steele on 6/20/24.
//

import CoreData
import CoreLocation
import MapKit
import SwiftUI
import Foundation

struct ContentView: View {
    @Environment(DataModel.self) private var dataModel
    @Environment(GlobalVariables.self) private var globalVars
    @Environment(LocationManager.self) private var locationManager
    
    @State private var viewModel: ViewModel = ViewModel()
    
    @State private var position: MapCameraPosition = .automatic
    @State private var mapSelection: MapSelection<AnnotatedMapItem>?
    @State private var mapItemSelected = false
    @State private var markerFromScreenTap:  AnnotatedMapItem?
    
    @State private var selectedLocation: LocationSetUp?
    @State private var searchDestinationSheetDetent: PresentationDetent = .fraction(0.5)
    @State private var selectedDetent: PresentationDetent = .fraction(0.5)

    @State private var showSheet = true
   
    
    var lineWidth: CGFloat = 5
    var lineColor: Color = .blue
    var outlineColor: Color = .black
    var outlineWidth: CGFloat = 1
    
    var body: some View {
        MapReader { proxy in
            Map(position: $viewModel.position, selection: $mapSelection) {
                ForEach(dataModel.allMapInfo) {mapInfo in
                    if let coordinate = mapInfo.startingPoint {
                        Marker(mapInfo.markerLabelStart,
                               systemImage: mapInfo.startIcon?.poiSymbol ?? "",
                               coordinate: coordinate)
                        .tint(mapInfo.startIcon?.poiColor ?? .red)
                    }
                    if let coordinate = mapInfo.endingPoint {
                        Marker(mapInfo.markerLabelEnd,
                               systemImage: mapInfo.endIcon?.poiSymbol ?? "",
                               coordinate: coordinate)
                        .tint(mapInfo.endIcon?.poiColor ?? .red)
                    }
                    MapPolyline(mapInfo.route ?? MKPolyline())
                        .stroke(
                            outlineColor,
                            style: StrokeStyle(
                                lineWidth: lineWidth + (outlineWidth * 2),
                                lineCap: .round,
                                lineJoin: .round
                            )
                        )
                    MapPolyline(mapInfo.route ?? MKPolyline())
                        .stroke(
                            lineColor,
                            style: StrokeStyle(
                                lineWidth: lineWidth,
                                lineCap: .round,
                                lineJoin: .round
                            )
                        )
                }
                
                //show current location on map
                UserAnnotation()
                // show marker when a location is selected on the map from coordinates and when searched
                ForEach(dataModel.results, id: \.self) { item in
                    Marker(item: item.item)
                        .tag(MapSelection(item))
                }
                if let markerFromScreenTap = markerFromScreenTap {
                    Marker(item: markerFromScreenTap.item)
                    .tag(MapSelection(markerFromScreenTap))
                }
                
            }
            .animation(.easeInOut(duration: 1), value: selectedDetent)
            .animation(.easeInOut(duration: 1), value: viewModel.position)
            .mapStyle(.standard(elevation: .realistic, pointsOfInterest: .all, showsTraffic: true))
            // This captures the coordinates on the screen.
            // There is a delay to accomodate the map to determine if the intention is to select a map item.
            .onTapGesture(perform: { screenposition in
                mapSelection = nil
                markerFromScreenTap = nil
                // prevent the user from selecting items when not adding a location
                if globalVars.showSearchLocationSheet {
                    mapItemSelected = false
                    if let coordinatesFromScreen = proxy.convert(screenposition, from: .local) {
                        print("TapGesture: \(Date().timeIntervalSince1970)")
                        let latitude = coordinatesFromScreen.latitude
                        let longitude = coordinatesFromScreen.longitude
                        
                        //Add a delay to allow AppleMaps to determine if a MapFeature has been selected, in parallel get address from coordinates
                        Task {
                            await withTaskGroup(of: Void.self) { group in
                                group.addTask {
                                    try? await Task.sleep(for: .milliseconds(700))
                                }
                                
                                group.addTask {
                                    try? await dataModel.getLocationPlacemark(location: CLLocation(latitude: latitude, longitude: longitude))
                                }
                                await group.waitForAll()
                            }
                            // with delay now can check if a mapItem was selected.  If not use the tapped locaiton
                            if !mapItemSelected {
                                print("map Item not selected")
                                if let mapAnnotation = dataModel.mapAnnotation {
                                    markerFromScreenTap = mapAnnotation
                                    print("Selected location from map Coordinates \(Date().timeIntervalSince1970)")
                                    selectedLocation = LocationSetUp(from: mapAnnotation)
                                }
                            } else {
                                print("map item is selected")
                            }
                        }
                    }
                }
            })
                    }
            .onAppear {
                print("on Appear")
                Task {
                    try await dataModel.getCurrentLocation(locationManager: locationManager)
                    print(dataModel.currentLocation)
                }
            }
            // This captures when a MapFeature(Apple built in markers shown on map)
            // or a MKMapItem (Markers from search results and converted from the onTapGesture)
            // is selected and triggers the LocationSetupView
            .onChange(of: mapSelection) {
                print("mapSelection Changed: \(Date().timeIntervalSince1970)")
                if let mapSelection = mapSelection {
                    mapItemSelected = true
                    print("map Item Selected is true")
                    //dataModel.results = []
                    if let mapFeature = mapSelection.feature {
                        print(mapSelection.feature?.coordinate ?? "no title")
                        // Get Feature address info from coordinates
                        Task {
                            try await dataModel.getLocationPlacemark(location: CLLocation(latitude: mapFeature.coordinate.latitude, longitude: mapFeature.coordinate.longitude))
                            if let mapAnnotation = dataModel.mapAnnotation {
                                let title = mapAnnotation.item.placemark.title
                                let subtitle = mapAnnotation.item.placemark.subtitle
                                print("selectedLocation from MapFeature")
                                selectedLocation = LocationSetUp(from: mapFeature, title: title ?? "" , subtitle: subtitle ?? "" )
                            }
                        }
                    } else if let  mapItem = mapSelection.value {
                        selectedLocation = LocationSetUp(from: mapItem)
                        print("selectedLocation from MapItem")
                    } else {
                        mapItemSelected = false
                    }
                    
                } else {
                    mapItemSelected = false
                    print("mapSelection is nil")
                }
            }
            .onChange(of: selectedLocation) {
                print(" selected location Changed")
                if let _ = selectedLocation {
                    globalVars.showLocationSetUpView = true
                }
            }
            //        .onChange(of: selectedDetent) {
            //            print("detent Changed")
            //            globalVars.selectedDetent = selectedDetent
            //        }
            //        .onChange(of: globalVars.selectedDetent) {
            //            selectedDetent = globalVars.selectedDetent
            //            viewModel.updateMapCameraPosition(dataModel: dataModel, globalVars: globalVars)
            //            print("detent Changed")
            //        }
//            .onChange(of: globalVars.selectedTabIndex) {
//                Task {
//                    print("tab Changed")
//                    dataModel.results = []
//                    dataModel.getMapInfo(selectedTabIndex: globalVars.selectedTabIndex, comprehensiveAndDailySegments: globalVars.comprehensiveAndDailySegments)
//                    //viewModel.updateMapCameraPosition(dataModel: dataModel, globalVars: globalVars)
//                    dataModel.mapCameraRegion = viewModel.position.region ?? MKCoordinateRegion()
//                    print(dataModel.mapCameraRegion)
//                }
//            }
//            .onChange(of: globalVars.showSearchLocationSheet) {
//                if globalVars.showSearchLocationSheet {
//                    selectedDetent = .fraction(0.12)
//                }
//            }
            .onChange(of: globalVars.comprehensiveAndDailySegments) {
                Task {
                    print("segment size: \(globalVars.comprehensiveAndDailySegments.count)")
                    dataModel.getMapInfo(selectedTabIndex: globalVars.selectedTabIndex, comprehensiveAndDailySegments: globalVars.comprehensiveAndDailySegments)
                    viewModel.updateMapCameraPosition(dataModel: dataModel, globalVars: globalVars)
                    dataModel.mapCameraRegion = viewModel.position.region ?? MKCoordinateRegion()
                }
            }
//            .onChange(of: dataModel.results) {
//                searchResults = dataModel.results
//                viewModel.updateMapCameraPosition(dataModel: dataModel, globalVars: globalVars)
//            }
//            .onChange(of: viewModel.position) {
//                print("position Changed")
//                dataModel.mapCameraRegion = viewModel.position.region ?? MKCoordinateRegion()
//            }
            .sheet(isPresented: $showSheet) {
                TripSetUpView()
                    .interactiveDismissDisabled()
                // Bug if the detent is < 0.12 that cause the the tabview to reset to tabSelected = 0
                    .presentationDetents([.fraction(0.12), .fraction(0.5), .fraction(0.9), .large], selection: $selectedDetent)
                    .presentationBackgroundInteraction(.enabled)
                    .sheet(isPresented: Binding(
                        get: { globalVars.showSearchLocationSheet },
                        set: { globalVars.showSearchLocationSheet = $0}
                    )) {
                        SearchDestinationView()
                            .presentationBackgroundInteraction(.enabled)
                            .presentationDetents([.fraction(0.12), .fraction(0.5), .fraction(0.9), .large], selection: $selectedDetent)
                            .onDisappear(perform: {
                                print("searchDestinationView dissappears")
                                globalVars.showSearchLocationSheet = false
                                dataModel.results = []
                            })
                            .sheet(isPresented: Binding(
                                get: { globalVars.showLocationSetUpView },
                                set: { globalVars.showLocationSetUpView = $0 }
                            )) {
                                if let trip = globalVars.selectedTrip {
                                    if let location = selectedLocation {
                                        LocationSetUpView(locationSetUp: location, trip: trip)
                                            .environment(LocationEditModel(locationSetUp: location, trip: trip))
                                            .presentationBackgroundInteraction(.enabled)
                                            .presentationDetents([.fraction(0.12), .fraction(0.5), .fraction(0.9), .large],
                                                                 selection: $selectedDetent)
                                            .onDisappear(perform: {
                                                print("locationSetUpView Dissapeared")
                                                mapSelection = nil
                                                selectedLocation = nil
                                                globalVars.showLocationSetUpView = false
                                                markerFromScreenTap = nil
                                            })
                                    }
                                }
                            }
                    }
            }
        }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, DataController.preview)
        .environment(DataModel())
        .environment(GlobalVariables())
        .environment(LocationManager())
}

/*
 When to update Camera Position:
 
 1. onAppear
    show the region bounded by the saved trips
    Show region bounded by route polyline
    balance scaling to maximize resolution
    if no trips show region equivalent to "State" based on current location
 2. when selected tab changes
    Show region bounded by route polyline
    balance scaling to maximize resolution
    if single location use .automatic or MKMapItem or a default span
 3. when LoccationSetUp sheet is shown
    Will be a single location
    Position determined by .automatic or MKMapItem or a default span
 4. When search results are shown
    Position should be able to use .automatic
 5. When sheet detent changes
    Capture region with "full screen" and adjust camera when sheet is exposed
 6. When LocationSetUp disappears
    Go back to overview of the current day
 
 When to clear mapSelection - Can be either a MapFeature or a AnnotatedMapItem
    Clean when searchResults is > 0
    Clear when LocationSetUpView sheet is dismissed
    Clear when SearchDestinationView sheet is dismissed
 
 When to clear searchResults - Shows MKMapItems as output of searchResults and when a location is selected with onTapGesture
     There is a local version and a global version
     When a mapSelection is made the local search results should be cleared
     if LocationSetUpView sheet is closed the global search results should repopulate the local search results
    Both search results should be cleared when SearchDestination View is closed
 
 When to clear selectedLocation
    LocationSetUpView sheet is dismissed
    
 
 When to clear selectedLocation
 
 */
