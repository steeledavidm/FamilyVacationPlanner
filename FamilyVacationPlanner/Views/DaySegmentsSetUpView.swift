//
//  DaySegmentsSetUpView.swift
//  FamilyVacationPlanner
//
//  Created by David Steele on 9/3/24.
//

import SwiftUI

struct DaySegmentsSetUpView: View {
    
    @Environment(GlobalVariables.self) private var globalVars
    
    @State private var selectedTabIndex: Int = 0
    @State var trip: Trip
    
    var body: some View {
        TabView(selection: $selectedTabIndex) {
            List {
                // if startLocation not set:
                Button("Select Start Location") {
                    globalVars.showSearchLocationSheet = true
                    globalVars.locationType = .startLocation
                }
                Button("Add Stop") {
                    globalVars.showSearchLocationSheet = true
                    globalVars.locationType = .pointOfInterest
                }
                Button("Select End Location") {
                    globalVars.showSearchLocationSheet = true
                    globalVars.locationType = .overNightStop
                }
            }
        }
        .onAppear() {
            globalVars.trip = trip
            selectedTabIndex = globalVars.selectedTabIndex
        }
    }
}

//#Preview {
//    DaySegmentsSetUpView()
//}
