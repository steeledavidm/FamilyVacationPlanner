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
    
    @State private var currentLocation: CLLocation = CLLocation()
    @State private var currentLocationPlacemark: CLPlacemark?
    @State private var locationFromMap: AnnotationItem?
    @State private var locationSetupDetent: PresentationDetent = .fraction(0.5)
    @State private var position: MapCameraPosition = .automatic
    @State private var selectedDetent: PresentationDetent = .fraction(0.5)
    @State private var selectedLocation: AnnotatedMapItem?
    @State private var selectedMarker: AnnotatedMapItem?
    @State private var selectedTabIndex: Int = 0
    @State private var searchDestinationSheetDetent: PresentationDetent = .fraction(0.5)
    @State private var searchResults: [AnnotatedMapItem] = []
    @State private var showSheet = true
    @State private var showSearchLocationSheet = false
    @State private var viewModel: ViewModel = ViewModel(selectedTabIndex: 0, selectedDetent: .fraction(0.5))
    @State private var comprehensiveAndDailySegments: [DaySegments] = []
    @State private var locationMOC: Location?
    

    var body: some View {
        ZStack {
            MapReader { proxy in
                Map(position: $position, selection: $selectedMarker) {
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
                            .stroke(.blue, lineWidth: 5)
                    }
                    ForEach(searchResults, id: \.self) { item in
                        Marker(item: item.item)
                    }
                    //show current location on map
                    UserAnnotation()
                }
                .animation(.easeInOut(duration: 1), value: selectedDetent)
                .animation(.easeInOut(duration: 1), value: position)
                .mapStyle(.standard(elevation: .realistic, pointsOfInterest: .all, showsTraffic: true))
                
                .onTapGesture(perform: { screenposition in
                    print("markerSelected: \(globalVars.markerSelected)")
                    //if !globalVars.displaySearchedLocations {
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
                            viewModel.updateMapCameraPosition(currentLocation: currentLocation, dataModel: dataModel, globalVars: globalVars)
                            position = viewModel.position
                            globalVars.markerSelected = false
                        }
                    //}
                })
            }
            .onAppear {
                print("on Appear")
                viewModel.selectedDetent = globalVars.selectedDetent
                Task {
                    currentLocation = try await dataModel.getCurrentLocation(locationManager: locationManager)
                    try await dataModel.getLocationPlacemark(location: currentLocation)
                    viewModel.updateMapCameraPosition(currentLocation: currentLocation, dataModel: dataModel, globalVars: globalVars)
                    position = viewModel.position
                    print(dataModel.locationPlacemark?.thoroughfare ?? "no street")
        
                }
            }
            .onChange(of: selectedDetent) {
                globalVars.selectedDetent = selectedDetent
            }
            .onChange(of: globalVars.selectedDetent) {
                selectedDetent = globalVars.selectedDetent
                viewModel.selectedDetent = selectedDetent
                viewModel.updateMapCameraPosition(currentLocation: currentLocation, dataModel: dataModel, globalVars: globalVars)
                position = viewModel.position
                print("detent Changed")
            }
            .onChange(of: globalVars.selectedTabIndex) {
                print("tab Changed")
                comprehensiveAndDailySegments = globalVars.comprehensiveAndDailySegments
                selectedTabIndex = globalVars.selectedTabIndex
                viewModel.selectedTabIndex = selectedTabIndex
                dataModel.getMapInfo(selectedTabIndex: selectedTabIndex, comprehensiveAndDailySegments: comprehensiveAndDailySegments)
                viewModel.updateMapCameraPosition(currentLocation: currentLocation, dataModel: dataModel, globalVars: globalVars)
                position = viewModel.position
                dataModel.mapCameraRegion = position.region ?? MKCoordinateRegion()
                //dataModel.getRoute()
            }
            .onChange(of: globalVars.showSearchLocationSheet) {
                showSearchLocationSheet = globalVars.showSearchLocationSheet
                print("showSearchLocationSheet: \(globalVars.showSearchLocationSheet)")
            }
            .onChange(of: globalVars.comprehensiveAndDailySegments) {
                print("segment size: \(globalVars.comprehensiveAndDailySegments.count)")
                comprehensiveAndDailySegments = globalVars.comprehensiveAndDailySegments
                dataModel.getMapInfo(selectedTabIndex: selectedTabIndex, comprehensiveAndDailySegments: comprehensiveAndDailySegments)
                viewModel.updateMapCameraPosition(currentLocation: currentLocation, dataModel: dataModel, globalVars: globalVars)
                position = viewModel.position
                dataModel.mapCameraRegion = position.region ?? MKCoordinateRegion()
                //dataModel.getRoute()
            }
            .onChange(of: dataModel.results) {
                print("resultscount \(dataModel.results.count)")
                searchResults = dataModel.results
                //print(searchResults)
                print("data model result changed")
                viewModel.updateMapCameraPosition(currentLocation: currentLocation, dataModel: dataModel, globalVars: globalVars)
                position = viewModel.position
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
                
            }
            .onChange(of: position) {
                print("position Changed")
                dataModel.mapCameraRegion = position.region ?? MKCoordinateRegion()
            }
            .onChange(of: dataModel.locationPlacemark) {
                print("Location Placemark changed")
                print(dataModel.locationPlacemark?.thoroughfare ?? "No street!!!")
            }
            .onChange(of: selectedLocation) {oldValue, newValue in
                if let selectedLocation = selectedLocation {
                    locationMOC = dataModel.generateLocation(selectedLocation: selectedLocation, locationType: globalVars.locationType ?? LocationType.pointOfInterest)
                }
            }
        }
        .sheet(isPresented: $showSheet) {
            TripSetUpView()
                .interactiveDismissDisabled()
                .presentationDetents([.fraction(0.5), .fraction(0.9), .fraction(0.1), .large], selection: $selectedDetent)
                .presentationBackgroundInteraction(.enabled)
                .sheet(isPresented: $showSearchLocationSheet) {
                    SearchDestinationView()
                        .presentationBackgroundInteraction(.enabled)
                        .presentationDetents([.fraction(0.5), .fraction(0.9), .fraction(0.1)], selection: $selectedDetent)
                        .onDisappear(perform: {
                            globalVars.showSearchLocationSheet = false
                        })
                        .sheet(item: $locationMOC) { locationMOC in
                            LocationSetUpView(locationMOC: locationMOC)
                            .presentationBackgroundInteraction(.enabled)
                            .presentationDetents([.fraction(0.5), .fraction(0.9), .fraction(0.1)], selection: $locationSetupDetent)
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
