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
    
    @State private var currentLocation: CLLocation = CLLocation()
    @State private var position: MapCameraPosition = .automatic
    @State private var selectedDetent: PresentationDetent = .fraction(0.5)
    @State private var selectedTabIndex: Int = 0
    @State private var showSheet = true
    @State private var trip: Trip = Trip()
    @State private var viewModel = ViewModel()

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
                selectedDetent = globalVars.selectedDetent
                dataModel.getCurrentLocation(completionHandler: { currentCLLocation in
                    print("name: \(String(describing: currentCLLocation?.name))")
                    print("address: \(String(describing: currentCLLocation?.thoroughfare))")
                    currentLocation = currentCLLocation?.location ?? CLLocation(latitude: 0, longitude: 0)
                    position = viewModel.updateMapCameraPosition(selectedTabIndex: selectedTabIndex, selectedDetent: selectedDetent, currentLocation: currentLocation)
                })
            }
            .onChange(of: selectedDetent) {
                globalVars.selectedDetent = selectedDetent
                position = viewModel.updateMapCameraPosition(selectedTabIndex: selectedTabIndex, selectedDetent: selectedDetent, currentLocation: currentLocation)
            }
            .onChange(of: globalVars.selectedDetent) {
                selectedDetent = globalVars.selectedDetent
                position = viewModel.updateMapCameraPosition(selectedTabIndex: selectedTabIndex, selectedDetent: selectedDetent, currentLocation: currentLocation)
                print("detent Changed")
            }
            .onChange(of: globalVars.selectedTabIndex) {
                selectedTabIndex = globalVars.selectedTabIndex
                position = viewModel.updateMapCameraPosition(selectedTabIndex: selectedTabIndex, selectedDetent: selectedDetent, currentLocation: currentLocation)
                print("tab Changed")
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
