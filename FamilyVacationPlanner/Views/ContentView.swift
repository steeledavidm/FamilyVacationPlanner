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
    @State private var position: MapCameraPosition = .automatic
    @State private var selectedDetent: PresentationDetent = .fraction(0.5)
    @State private var selectedTabIndex: Int = 0
    @State private var showSheet = true
    @State private var showSearchLocationSheet = false
    @State private var trip: Trip = Trip()
    @State private var viewModel: ViewModel = ViewModel(selectedTabIndex: 0, selectedDetent: .fraction(0.5))
    

    var body: some View {
        ZStack {
            MapReader {proxy in
                Map(position: $position) {
                    ForEach(dataModel.allMapInfo) {mapInfo in
                        Marker(mapInfo.markerLabelStart, coordinate: mapInfo.startingPoint ?? CLLocationCoordinate2D())
                        Marker(mapInfo.markerLabelEnd, coordinate: mapInfo.endingPoint ?? CLLocationCoordinate2D())
                        MapPolyline(mapInfo.route ?? MKRoute())
                            .stroke(.blue, lineWidth: 5)
                    }
                }
                .animation(.easeInOut(duration: 1), value: selectedDetent)
                .animation(.easeInOut(duration: 1), value: position)
                .mapStyle(.hybrid(elevation: .realistic, pointsOfInterest: .all, showsTraffic: true))
                .gesture (
                    LongPressGesture(minimumDuration: 0.5)
                        .onChanged { value in
                            isLongPressActive = value
                            print(isLongPressActive)
                        }
                        .onEnded { _ in
                            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                        }
                        .sequenced(before: DragGesture(minimumDistance: 0))
                        .onEnded { value in
                            switch value {
                            case .second(true, let drag):
                                if let location = drag?.location {
                                    let coordinate = proxy.convert(location, from: .local)
                                    if let pin = coordinate {

                                        print("Tapped at \(String(describing: coordinate))")
                                        locationFromMap = AnnotationItem(name: "New Location", title: "", subtitle: "", latitude: pin.latitude, longitude: pin.longitude)
                                    }
                                }
                            default:
                                break
                            }
                        }
                )
            }
            .onAppear {
                viewModel.selectedDetent = globalVars.selectedDetent
                Task {
                    currentLocationPlacemark = try await dataModel.getCurrentLocation(locationManager: locationManager)
                    currentLocation = CLLocation(latitude: currentLocationPlacemark?.location?.coordinate.latitude ?? 0.0, longitude: currentLocationPlacemark?.location?.coordinate.longitude ?? 0.0)
                    viewModel.updateMapCameraPosition(currentLocation: currentLocation, dataModel: dataModel)
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
                viewModel.updateMapCameraPosition(currentLocation: currentLocation, dataModel: dataModel)
                position = viewModel.position
                print("detent Changed")
            }
            .onChange(of: globalVars.selectedTabIndex) {
                print("tab Changed")
                selectedTabIndex = globalVars.selectedTabIndex
                viewModel.selectedTabIndex = selectedTabIndex
                dataModel.getMapInfo(selectedTabIndex: selectedTabIndex)
                viewModel.updateMapCameraPosition(currentLocation: currentLocation, dataModel: dataModel)
                position = viewModel.position
                dataModel.getRoute()
            }
            .onChange(of: globalVars.showSearchLocationSheet) {
                showSearchLocationSheet = globalVars.showSearchLocationSheet
            }
            .onChange(of: globalVars.trip) {
                trip = globalVars.trip ?? Trip()
            }
        }
        .sheet(isPresented: $showSheet) {
            TripSetUpView()
                .interactiveDismissDisabled()
                .presentationDetents([.fraction(0.5), .fraction(0.9), .fraction(0.1), .large], selection: $selectedDetent)
                .presentationBackgroundInteraction(.enabled)
                .sheet(isPresented: $showSearchLocationSheet) {
                    SearchDestinationView(trip: trip)
                        .interactiveDismissDisabled()
                        .presentationBackgroundInteraction(.enabled)
                        .presentationDetents([.fraction(0.5), .fraction(0.9), .fraction(0.1)])
                }
        }
    }
}
