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
    private var globalVars = GlobalVariables()
    private var dataModel = DataModel()
    private var locationManager = LocationManager()
    private var locationEditModel = LocationEditModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, dataController.container.viewContext)
                .environment(globalVars)
                .environment(dataModel)
                .environment(locationManager)
                .environment(locationEditModel)
        }
    }
}

extension Binding {
    func toUnwrapped<T>(defaultValue: T) -> Binding<T> where Value == Optional<T>  {
        Binding<T>(get: { self.wrappedValue ?? defaultValue }, set: { self.wrappedValue = $0 })
    }
}
