//
//  EditLocationView.swift
//  FamilyVacationPlanner
//
//  Created by David Steele on 11/7/24.
//

import CoreData
import SwiftUI

struct EditLocationView: View {
    @Environment(DataModel.self) private var dataModel
    @ObservedObject var location: Location
    @State private var locationIndex: String = ""
    @State private var numberOfNights: String = ""
    
    var body: some View {
        List {
            Text("Date Arrived: \(location.dateArrive ?? Date(), style: .date))")
            Text("Date Leave: \(location.dateLeave ?? Date(), style: .date))")
            TextField("Name", text: $location.name.toUnwrapped(defaultValue: ""))
            TextField("Notes", text: $location.notes.toUnwrapped(defaultValue: ""))
            Toggle("Over Night Stop", isOn: $location.overNightStop)
                .toggleStyle(.switch)
            if location.overNightStop {
                TextField("Number of Nights", text: $numberOfNights)
                .keyboardType(.numberPad)
                .onChange(of: numberOfNights) {
                    if let parsed = Int(numberOfNights) {
                        location.numberOfNights = Int16(parsed)
                    }
                }
            }
            
            Toggle("Primary", isOn: $location.primary)
                .toggleStyle(.switch)
            Toggle("Start Location", isOn: $location.startLocation)
                .toggleStyle(.switch)
            TextField("Location Index", text: $locationIndex)
            .keyboardType(.numberPad)
            .onChange(of: locationIndex) {
                if let parsed = Int(locationIndex) {
                   location.locationIndex = Int16(parsed)
               }
           }
            Button(action: {
                try? dataModel.moc.save()
            }, label: {
                Text("Save Location")
            })
            
        }
        .onAppear {
            locationIndex = String(location.locationIndex)
            numberOfNights = String(location.numberOfNights)
        }
    }
}

#Preview {
    let context = DataController.preview
    let locations: [Location]
    let requestLocations: NSFetchRequest<Location> = Location.fetchRequest()
    do {
        locations = try context.fetch(requestLocations)
    } catch {
        let nserror = error as NSError
        fatalError("Error \(nserror): \(nserror.userInfo)")
    }
    let location = locations[0]
    return EditLocationView(location: location)
        .environment(\.managedObjectContext, DataController.preview)
        .environment(DataModel())
}
