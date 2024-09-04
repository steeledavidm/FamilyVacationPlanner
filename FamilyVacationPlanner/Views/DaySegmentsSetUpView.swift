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
    @State private var trip: Trip = Trip()
    
    var body: some View {
        TabView(selection: $selectedTabIndex) {
            List {
                Button("Select Start Location") {
                    globalVars.showSearchLocationSheet = true
                    globalVars.locationType = .startLocation
                }
                Button("Select End Location") {
                    globalVars.showSearchLocationSheet = true
                    globalVars.locationType = .endLocation
                }
            }
        }
        .onAppear() {
            trip = globalVars.trip ?? Trip()
            selectedTabIndex = globalVars.selectedTabIndex
        }
    }
}

#Preview {
    DaySegmentsSetUpView()
}
