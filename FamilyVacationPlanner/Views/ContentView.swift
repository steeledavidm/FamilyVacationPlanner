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
    
    @State private var selectedDetent: PresentationDetent = .fraction(0.5)
    @State private var selectedLocation: LocationSetUp?
    @State private var searchDestinationSheetDetent: PresentationDetent = .fraction(0.5)
    @State private var searchResults: [AnnotatedMapItem] = []
    @State private var showSheet = true
    @State private var showSearchLocationSheet = false
    @State private var showLocationSetUpView = false
    @State private var viewModel: ViewModel = ViewModel()
    @State private var mapSelection: MapSelection<AnnotatedMapItem>?
    
    @State private var coordinates: CLLocation?
    @State private var selectedItem: SelectedItem?
    @State private var selectedItemType: SelectedItemType?
    @State private var picture: Image?
    @State private var poiCategory: String?

    var lineWidth: CGFloat = 5
    var lineColor: Color = .blue
    var outlineColor: Color = .black
    var outlineWidth: CGFloat = 1
    
    var body: some View {
        MapReader { proxy in
            Map(position: $viewModel.position, selection: $mapSelection) {
                ForEach(searchResults, id: \.self) { item in
                    Marker(item: item.item)
                        .tag(MapSelection(item))
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
            .animation(.easeInOut(duration: 1), value: selectedDetent)
            .animation(.easeInOut(duration: 1), value: viewModel.position)
            .mapStyle(.standard(elevation: .realistic, pointsOfInterest: .all, showsTraffic: true))
            
            // This captures the coordinates on the screen.  The Coordinates are translated to an Address and then
            // populated into the Results Array and will show as a marker on the map.  Will trigger LocationSetUpView
            // Everytime the screen is tapped the LocationSetUpView will be initiallized the selected coordinates.
            // if there is a MapFeature or MKMapItem in the area tapped the LocationSetUpView will refresh when mapSelection updates
            // to show the additonal info provided by those features.
            .onTapGesture(perform: { screenposition in
                if showSearchLocationSheet {
                    if let coordinate = proxy.convert(screenposition, from: .local) {
                        print("TapGesture")
                        let latitude = coordinate.latitude
                        let longitude = coordinate.longitude
                        coordinates = CLLocation(latitude: latitude, longitude: longitude)
                        if let coordinates = coordinates {
                            selectedItemType = SelectedItemType.new(coordinates)
                        }
                        Task {
                            try await dataModel.getLocationPlacemark(location: CLLocation(latitude: latitude, longitude: longitude))
                            if !globalVars.markerSelected {
                                if let mapAnnotation = dataModel.mapAnnotation {
                                    dataModel.results = []
                                    dataModel.results.append(mapAnnotation)
                                    selectedLocation = LocationSetUp(from: mapAnnotation)
                                }
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
            print("selected Map Feature Info")
            if let mapSelection = mapSelection {
                selectedItemType = SelectedItemType.existing(mapSelection)
                if let annotatedMapItem = mapSelection.value {
                    dataModel.results.append(annotatedMapItem)
                    selectedLocation = LocationSetUp(from: annotatedMapItem)
                }
                if let mapFeature = mapSelection.feature {
                    print("mapFeatureName: \(String(describing: mapFeature.title))")
                    print("mapFeatureCoordinates: \(mapFeature.coordinate.latitude), \(mapFeature.coordinate.longitude)")
                    Task {
                        try await dataModel.getLocationPlacemark(location: CLLocation(latitude: mapFeature.coordinate.latitude, longitude: mapFeature.coordinate.longitude))
                        if let mapAnnotation = dataModel.mapAnnotation {
                            let title = mapAnnotation.item.placemark.title
                            let subtitle = mapAnnotation.item.placemark.subtitle
                            selectedLocation = LocationSetUp(from: mapFeature, title: title ?? "" , subtitle: subtitle ?? "" )
                        }
                    }
                }
                globalVars.markerSelected = true
                dataModel.plotRecentItems = false
            } else {
                globalVars.markerSelected = false
            }
            print("selectedLocationchanged: \(globalVars.markerSelected)")
        }
        .onChange(of: selectedLocation) {
            showLocationSetUpView = true
            if mapSelection != nil {
                searchResults = []
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
                dataModel.results = []
                dataModel.getMapInfo(selectedTabIndex: globalVars.selectedTabIndex, comprehensiveAndDailySegments: globalVars.comprehensiveAndDailySegments)
                viewModel.updateMapCameraPosition(dataModel: dataModel, globalVars: globalVars)
                dataModel.mapCameraRegion = viewModel.position.region ?? MKCoordinateRegion()
            }
        }
        .onChange(of: globalVars.showSearchLocationSheet) {
            showSearchLocationSheet = globalVars.showSearchLocationSheet
            if showSearchLocationSheet {
                selectedDetent = .fraction(0.12)
            }
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
            searchResults = dataModel.results
            viewModel.updateMapCameraPosition(dataModel: dataModel, globalVars: globalVars)
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
                            print("searchDestinationView dissappears")
                            globalVars.showSearchLocationSheet = false
                        })
                        .sheet(isPresented: $showLocationSetUpView) {
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
