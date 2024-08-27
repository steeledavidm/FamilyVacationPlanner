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
    @State private var sheetDetent: PresentationDetent = .fraction(0.5)
    var body: some View {
    
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
        }
        .sheet(isPresented: $showSheet, content: {
            TripSetUpView()
                .interactiveDismissDisabled()
                .presentationDetents([.fraction(0.5), .fraction(0.9), .fraction(0.1)], selection: $sheetDetent)
                .presentationBackgroundInteraction(.enabled)
                .sheet(isPresented: $showSheet, content: {
                    Text("Second Sheet")
                })
                
        })
    }
}



#Preview {
    ContentView().environment(\.managedObjectContext, DataController.preview)
}
