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
    @State private var mapItemSelected: AnnotatedMapItem?
    @State private var position: MapCameraPosition = .automatic
    @State private var selectedDetent: PresentationDetent = .fraction(0.5)
    @State private var selectedLocation: AnnotatedMapItem?
    @State private var selectedTabIndex: Int = 0
    @State private var searchDestinationSheetDetent: PresentationDetent = .fraction(0.5)
    @State private var searchResults: [AnnotatedMapItem] = []
    @State private var showSheet = true
    @State private var showSearchLocationSheet = false
    @State private var trip: Trip = Trip()
    @State private var viewModel: ViewModel = ViewModel(selectedTabIndex: 0, selectedDetent: .fraction(0.5))
    

    var body: some View {
        ZStack {
            MapReader { proxy in
                Map(position: $position, selection: $selectedLocation) {
                    ForEach(dataModel.allMapInfo) {mapInfo in
                        Marker(mapInfo.markerLabelStart, coordinate: mapInfo.startingPoint ?? CLLocationCoordinate2D())
                        Marker(mapInfo.markerLabelEnd, coordinate: mapInfo.endingPoint ?? CLLocationCoordinate2D())
                        MapPolyline(mapInfo.route ?? MKRoute())
                            .stroke(.blue, lineWidth: 5)
                    }
                    ForEach(searchResults, id: \.self) { item in
                        Marker(item: item.item)
                    }
                    UserAnnotation()
                }
                .animation(.easeInOut(duration: 1), value: selectedDetent)
                .animation(.easeInOut(duration: 1), value: position)
                .animation(.easeInOut(duration: 1), value: mapItemSelected)
                .mapStyle(.hybrid(elevation: .realistic, pointsOfInterest: .all, showsTraffic: true))
                
                .onTapGesture(perform: { position in
                    if !globalVars.displaySearchedLocations {
                        if let coordinate = proxy.convert(position, from: .local) {
                            print("TapGesture")
                            searchResults = []
                            let latitude = coordinate.latitude
                            let longitude = coordinate.longitude
                            Task {
                                try await dataModel.getLocationPlacemark(location: CLLocation(latitude: latitude, longitude: longitude))
                                selectedLocation = dataModel.mapAnnotation
                                
                                if let unWrappedLocation = selectedLocation {
                                    searchResults.append(unWrappedLocation)
                                    print("location is selected")
                                }
                            }
                        }
                    }
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
                }
            }
            .onChange(of: selectedDetent) {
                globalVars.selectedDetent = selectedDetent
            }
            .onChange(of: globalVars.selectedDetent) {
                print(currentLocation)
                selectedDetent = globalVars.selectedDetent
                viewModel.selectedDetent = selectedDetent
                viewModel.updateMapCameraPosition(currentLocation: currentLocation, dataModel: dataModel, globalVars: globalVars)
                position = viewModel.position
                print("detent Changed")
            }
            .onChange(of: globalVars.selectedTabIndex) {
                print("tab Changed")
                selectedTabIndex = globalVars.selectedTabIndex
                viewModel.selectedTabIndex = selectedTabIndex
                dataModel.getMapInfo(selectedTabIndex: selectedTabIndex)
                viewModel.updateMapCameraPosition(currentLocation: currentLocation, dataModel: dataModel, globalVars: globalVars)
                position = viewModel.position
                dataModel.mapCameraRegion = position.region ?? MKCoordinateRegion()
                dataModel.getRoute()
            }
            .onChange(of: globalVars.showSearchLocationSheet) {
                showSearchLocationSheet = globalVars.showSearchLocationSheet
                print("showSearchLocationSheet: \(globalVars.showSearchLocationSheet)")
            }
            .onChange(of: globalVars.trip) {
                print("trip changed")
                trip = globalVars.trip ?? Trip()
            }
            .onChange(of: dataModel.results) {
                print("resultscount \(dataModel.results.count)")
                searchResults = dataModel.results
                print(searchResults)
                print("data model result changed")
                viewModel.updateMapCameraPosition(currentLocation: currentLocation, dataModel: dataModel, globalVars: globalVars)
                position = viewModel.position
            }

            .onChange(of: selectedLocation) {
                if let selectedAnnotation = selectedLocation {
                    print("selectionChanged")
                    let mkMapItem = selectedLocation?.item ?? MKMapItem()
                    let coordinate: CLLocationCoordinate2D = mkMapItem.placemark.coordinate
                    let latitude = coordinate.latitude
                    let longitude = coordinate.longitude
                    print(mkMapItem.name ?? "")
                    print(mkMapItem.placemark)
                    mapItemSelected = selectedAnnotation
                    globalVars.locationFromMap = AnnotationItem(name: "", title: "", subtitle: "", latitude: latitude, longitude: longitude)
                    dataModel.plotRecentItems = true
                    viewModel.updateMapCameraPosition(currentLocation: currentLocation, dataModel: dataModel, globalVars: globalVars)
                    position = viewModel.position
                }
            }
            .onChange(of: position) {
                print("position Changed")
                dataModel.mapCameraRegion = position.region ?? MKCoordinateRegion()
            }
            .onChange(of: mapItemSelected) {
                print("selected map item changed")
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
                        .sheet(item: $mapItemSelected) { selectedItem in
                            LocationSetUpView(locationFromMap: selectedItem)
                            .presentationBackgroundInteraction(.enabled)
                            .presentationDetents([.fraction(0.5), .fraction(0.9), .fraction(0.1)], selection: $selectedDetent)
                        }
                }
        }
    }
}
