//
//  ContentView.swift
//  FamilyVacationPlanner
//
//  Created by David Steele on 6/20/24.
//

import CoreData
import MapKit
import SwiftUI
import Foundation

struct ContentView: View {
    
    @State var coordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)
    @State var markerIndex = 0
    @State var showSheet = true
    var body: some View {
        
        TabView {
            MapReader { proxy in
                Map() {
                    if coordinate.latitude != 0 {
                        Marker("Selected Location", coordinate: coordinate)
                    }
                }
                .mapStyle(.hybrid(elevation: .realistic, pointsOfInterest: .all, showsTraffic: true))
                .onTapGesture { position in
                    if let coordinate = proxy.convert(position, from: .local) {
                        print(coordinate)
                    }
                }
                .sheet(isPresented: $showSheet, content: {
                    TripSetUpView()
                        .interactiveDismissDisabled()
                        .presentationDetents([.fraction(0.5), .fraction(0.9), .fraction(0.1)])
                        .sheet(isPresented: $showSheet, content: {
                            Text("Second Sheet")
                        })
                        
                })

            }
            .tabItem {
                Label("map", systemImage: "map")
            }
        
            
            
            AllDestinationsView()
                .tabItem {
                    Label("All", systemImage: "list.dash")
                }
            //.toolbar(.hidden, for: .tabBar)
            TripSetUpView()
                .tabItem {
                    Label("Trips", systemImage: "steeringwheel")
                }
            toolbar(.hidden, for: .tabBar)
            
        }
    }
}

extension Binding {
    func toUnwrapped<T>(defaultValue: T) -> Binding<T> where Value == Optional<T>  {
        Binding<T>(get: { self.wrappedValue ?? defaultValue }, set: { self.wrappedValue = $0 })
    }
}

#Preview {
    ContentView().environment(\.managedObjectContext, DataController.preview)
}
