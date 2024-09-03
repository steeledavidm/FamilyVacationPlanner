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
    @State private var position: MapCameraPosition = .automatic
    @State private var selectedDetent: PresentationDetent = .fraction(0.5)
    @State private var selectedTabIndex: Int = 0
    @State private var showSheet = true
    @State private var trip: Trip = Trip()
    @State private var viewModel: ViewModel = ViewModel(selectedTabIndex: 0, selectedDetent: .fraction(0.5))

    var body: some View {
        ZStack {
            MapReader {_ in
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
            }
            .onAppear {
                viewModel.selectedDetent = globalVars.selectedDetent
                Task {
                    await dataModel.getCurrentLocation(locationManager: locationManager)
                    currentLocation = dataModel.currentLocation
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
        }
        .sheet(isPresented: $showSheet) {
            TripSetUpView()
            .interactiveDismissDisabled()
            .presentationDetents([.fraction(0.5), .fraction(0.9), .fraction(0.1), .large], selection: $selectedDetent)
            .presentationBackgroundInteraction(.enabled)
        }
    }
}
