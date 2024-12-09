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
    
    @State private var currentLocationPlacemark: CLPlacemark?
    @State private var locationFromMap: AnnotationItem?
    //@State private var locationSetupDetent: PresentationDetent = .fraction(0.5)
    @State private var selectedDetent: PresentationDetent = .fraction(0.5)
    @State private var selectedLocation: AnnotatedMapItem?
    @State private var selectedMarker: AnnotatedMapItem?
    @State private var searchDestinationSheetDetent: PresentationDetent = .fraction(0.5)
    @State private var searchResults: [AnnotatedMapItem] = []
    @State private var showSheet = true
    @State private var showSearchLocationSheet = false
    @State private var viewModel: ViewModel = ViewModel()
    @State private var selectedFeature: MapFeature?
    @State private var showMapForSearchResultMarkers: Bool = false
    @State private var showTappedLocation: Bool = false

    var lineWidth: CGFloat = 5
    var lineColor: Color = .blue
    var outlineColor: Color = .black
    var outlineWidth: CGFloat = 1
    
    var body: some View {
        ZStack {
            if !showMapForSearchResultMarkers {
                VStack {
                    Text("Feature Selectable Map")
                    MapReader { proxy in
                        Map(position: $viewModel.position, selection: $selectedFeature) {
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
                            if showTappedLocation {
                                ForEach(searchResults, id: \.self) { item in
                                    Marker(item: item.item)
                                }
                            }
                        }
                        .animation(.easeInOut(duration: 1), value: selectedDetent)
                        .animation(.easeInOut(duration: 1), value: viewModel.position)
                        .mapStyle(.standard(elevation: .realistic, pointsOfInterest: .all, showsTraffic: true))
                        .onDisappear() {
                            showTappedLocation = false
                            selectedFeature = nil
                        }
                        .onTapGesture(perform: { screenposition in
                            print("markerSelected: \(globalVars.markerSelected)")
                            showTappedLocation = true
                            if globalVars.displaySearchedLocations {
                                if let coordinate = proxy.convert(screenposition, from: .local) {
                                    print("TapGesture")
                                    let latitude = coordinate.latitude
                                    let longitude = coordinate.longitude
                                    //print("\(latitude), \(longitude)")
                                    Task {
                                        try await dataModel.getLocationPlacemark(location: CLLocation(latitude: latitude, longitude: longitude))
                                        if !globalVars.markerSelected {
                                            searchResults = []
                                            selectedLocation = dataModel.mapAnnotation
                                            print("selectedLocation from tapGesture: \(globalVars.markerSelected)")
    
                                            if let unWrappedLocation = selectedLocation {
                                                searchResults.append(unWrappedLocation)
                                                print("location is selected")
                                            }
                                        } else {
                                            selectedLocation = selectedMarker
                                            print("selectedLocation updated in else")
                                        }
                                    }
                                    globalVars.locationFromMap = AnnotationItem(name: "", title: "", subtitle: "", latitude: latitude, longitude: longitude)
                                    dataModel.plotRecentItems = true
                                    viewModel.updateMapCameraPosition(dataModel: dataModel, globalVars: globalVars)
                                    globalVars.markerSelected = false
                                }
                            }
                        })
                    }
                }
            } else {
                VStack {
                    Text("Marker Selectable Map")
                    Map(position: $viewModel.position, selection: $selectedMarker) {
                        ForEach(searchResults, id: \.self) { item in
                            Marker(item: item.item)
                        }
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
                    }
                }
            }
        }
        .onAppear {
            print("on Appear")
            Task {
                try await dataModel.getCurrentLocation(locationManager: locationManager)
                print(dataModel.currentLocation)
            }
        }
        .onChange(of: selectedDetent) {
            print("detent Changed")
            globalVars.selectedDetent = selectedDetent
        }
        .onChange(of: globalVars.selectedDetent) {
            selectedDetent = globalVars.selectedDetent
            viewModel.updateMapCameraPosition(dataModel: dataModel, globalVars: globalVars)
            print("detent Changed")
        }
        .onChange(of: globalVars.selectedTabIndex) {
            Task {
                print("tab Changed")
                selectedMarker = nil
                dataModel.results = []
                dataModel.getMapInfo(selectedTabIndex: globalVars.selectedTabIndex, comprehensiveAndDailySegments: globalVars.comprehensiveAndDailySegments)
                viewModel.updateMapCameraPosition(dataModel: dataModel, globalVars: globalVars)
                dataModel.mapCameraRegion = viewModel.position.region ?? MKCoordinateRegion()
            }
        }
        .onChange(of: globalVars.showSearchLocationSheet) {
            showSearchLocationSheet = globalVars.showSearchLocationSheet
            if globalVars.showSearchLocationSheet == false {
                selectedMarker = nil
                dataModel.results = []
            } else {
                selectedDetent = .fraction(0.12)
            }
            print("showSearchLocationSheet: \(globalVars.showSearchLocationSheet)")
        }
        .onChange(of: globalVars.comprehensiveAndDailySegments) {
            Task {
                print("segment size: \(globalVars.comprehensiveAndDailySegments.count)")
                dataModel.getMapInfo(selectedTabIndex: globalVars.selectedTabIndex, comprehensiveAndDailySegments: globalVars.comprehensiveAndDailySegments)
                viewModel.updateMapCameraPosition(dataModel: dataModel, globalVars: globalVars)
                dataModel.mapCameraRegion = viewModel.position.region ?? MKCoordinateRegion()
            }
        }
        .onChange(of: dataModel.results) {
            print("resultscount \(dataModel.results.count)")
            if dataModel.results.count > 1 {
                showMapForSearchResultMarkers = true
            } else {
                showMapForSearchResultMarkers = false
            }
            searchResults = dataModel.results
            print("data model result changed")
            viewModel.updateMapCameraPosition(dataModel: dataModel, globalVars: globalVars)
        }

        .onChange(of: selectedMarker) {
            print("marker changed: \(globalVars.markerSelected)")
            if let marker = selectedMarker {
                searchResults = []
                searchResults.append(marker)
                globalVars.markerSelected = true
                dataModel.plotRecentItems = false
            } else {
                globalVars.markerSelected = false
            }
            print("selectedLocationchanged: \(globalVars.markerSelected)")
            //selectedMarker = nil
        }
        .onChange(of: viewModel.position) {
            print("position Changed")
            dataModel.mapCameraRegion = viewModel.position.region ?? MKCoordinateRegion()
        }
        .sheet(isPresented: $showSheet) {
            TripSetUpView()
                .interactiveDismissDisabled()
            // Bug if the detent is < 0.12 that cause the the tabview to reset to tabSelected = 0
                .presentationDetents([.fraction(0.12), .fraction(0.5), .fraction(0.9), .large], selection: $selectedDetent)
                .presentationBackgroundInteraction(.enabled)
                .sheet(isPresented: $showSearchLocationSheet) {
                    SearchDestinationView()
                        .presentationBackgroundInteraction(.enabled)
                        .presentationDetents([.fraction(0.12), .fraction(0.5), .fraction(0.9), .large], selection: $selectedDetent)
                        .onDisappear(perform: {
                            globalVars.showSearchLocationSheet = false
                        })
                        .sheet(item: $selectedLocation) { location in
                            if let trip = globalVars.selectedTrip {
                                LocationSetUpView(annotatedMapItem: location, trip: trip)
                                    .presentationBackgroundInteraction(.enabled)
                                    .presentationDetents([.fraction(0.12), .fraction(0.5), .fraction(0.9), .large],
                                                         selection: $selectedDetent)
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
