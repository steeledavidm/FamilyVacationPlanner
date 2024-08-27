//
//  FamilyVacationPlannerApp.swift
//  FamilyVacationPlanner
//
//  Created by David Steele on 6/20/24.
//


import SwiftUI

@main
struct FamilyVacationPlannerApp: App {

    let dataController = DataController.shared
    @State private var globalVariables = GlobalVariables()
    @State private var viewModel = LocationsViewModel()

    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, dataController.container.viewContext)
                .environment(globalVariables)
                .environment(viewModel)
        }
    }
}

extension Binding {
    func toUnwrapped<T>(defaultValue: T) -> Binding<T> where Value == Optional<T>  {
        Binding<T>(get: { self.wrappedValue ?? defaultValue }, set: { self.wrappedValue = $0 })
    }
}
