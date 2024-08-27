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
    var body: some View {

        TabView {
            
            Map()
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
                //.toolbar(.hidden, for: .tabBar)

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
