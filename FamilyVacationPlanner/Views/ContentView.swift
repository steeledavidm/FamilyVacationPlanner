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
    @State private var isLongPressActive = false
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
                .mapStyle(.hybrid(elevation: .realistic, pointsOfInterest: .all, showsTraffic: true))
//                .gesture (
//                    LongPressGesture(minimumDuration: 0.5)
//                        .onChanged { value in
//                            isLongPressActive = value
//                            print(isLongPressActive)
//                        }
//                        .onEnded { _ in
//                            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
//                        }
//                        .sequenced(before: DragGesture(minimumDistance: 0))
//                        .onEnded { value in
//                            switch value {
//                            case .second(true, let drag):
//                                if let location = drag?.location {
//                                    let coordinate = proxy.convert(location, from: .local)
//                                    if let pin = coordinate {
//
//                                        print("Tapped at \(String(describing: coordinate))")
//                                        locationFromMap = AnnotationItem(name: "New Location", title: "", subtitle: "", latitude: pin.latitude, longitude: pin.longitude)
//                                    }
//                                }
//                            default:
//                                break
//                            }
//                        }
//                )
                .onTapGesture(perform: { position in
                    if let coordinate = proxy.convert(position, from: .local) {
                        locationFromMap = AnnotationItem(name: "New Location", title: "", subtitle: "", latitude: coordinate.latitude, longitude: coordinate.longitude)
                        print("TapGesture")
                        print(locationFromMap?.coordinate ?? CLLocation())
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
                    dataModel.mapCameraRegion = position.region ?? MKCoordinateRegion()
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
            .onChange(of: locationFromMap) {
                print("location From Map Changed")
                searchResults = []
                let latitude = locationFromMap?.latitude ?? 0
                let longitude = locationFromMap?.longitude ?? 0
                Task {
                    try await dataModel.getLocationPlacemark(location: CLLocation(latitude: latitude, longitude: longitude))
                    let selectionName = "\(dataModel.locationPlacemark?.name ?? "")"
                    var selectionAnnotatedMapItem = AnnotatedMapItem(item: MKMapItem())
                    selectionAnnotatedMapItem.item = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude)))
                    searchResults.append(selectionAnnotatedMapItem)
                    selectionAnnotatedMapItem.item.name = selectionName
                    selectedLocation = selectionAnnotatedMapItem
                    globalVars.locationFromMap = locationFromMap
                    viewModel.updateMapCameraPosition(currentLocation: currentLocation, dataModel: dataModel, globalVars: globalVars)
                    position = viewModel.position
                    print(selectionName)
                }
            }
            .onChange(of: selectedLocation) {
                if let selectedAnnotation = selectedLocation {
                    print("selectionChanged")
                    let mkMapItem = selectedLocation?.item ?? MKMapItem()
                    print(mkMapItem.name ?? "")
                    print(mkMapItem.placemark)
                    mapItemSelected = selectedAnnotation
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
                        .interactiveDismissDisabled()
                        .presentationBackgroundInteraction(.enabled)
                        .presentationDetents([.fraction(0.5), .fraction(0.9), .fraction(0.1)], selection: $selectedDetent)
                        .sheet(item: $mapItemSelected) { locationFromMap in
                            LocationSetUpView(locationFromMap: locationFromMap)
                                .presentationBackgroundInteraction(.enabled)
                                .presentationDetents([.fraction(0.5), .fraction(0.9), .fraction(0.1)], selection: $selectedDetent)
                        }
                }
        }
    }
}
