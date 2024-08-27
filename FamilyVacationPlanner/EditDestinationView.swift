//
//  EditDestinationView.swift
//  FamilyVacationPlanner
//
//  Created by David Steele on 6/22/24.
//

import CoreData
import SwiftUI

struct EditDestinationView: View {
    @State var location: Location
    
    //@Environment(\.managedObjectContext) var moc
    @Environment(LocationsViewModel.self) private var viewModel
    @Environment(GlobalVariables.self) private var globalVar
    @FocusState private var isFocusedTextField: Bool
    @State var overNightStopToggle: Bool = false
    @State var startLocationToggle: Bool = false
    @State var locationName: String = ""
    @State private var selectedTrip: Trip = Trip()
    
    @State private var startLocation: Bool = false
    @State private var overNightStop: Bool = false
    
    
    var body: some View {
        VStack {
            Form {
                Section(header: Text("Name")
                    .font(.headline)
                    .foregroundColor(.black)
                    .padding(EdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 0))
                ) {
                    TextField("Name", text: $location.name.toUnwrapped(defaultValue: ""))
                        .overlay {
                            ClearButton(text: $location.name.toUnwrapped(defaultValue: ""))
                                .padding(.top, 2)
                        }
                        .focused($isFocusedTextField)
                }
                .textCase(nil)
                
                Section(header: Text("Address")
                    .font(.headline)
                    .foregroundColor(.black)
                    .padding(EdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 0))
                ) {
                    TextField("Address", text: $location.title.toUnwrapped(defaultValue: ""))
                }
                .textCase(nil)
                
                VStack {
                    Toggle("Trip Start Location", isOn: $startLocation)
                        .toggleStyle(.switch)
                    if !startLocation {
                        Toggle("Over Night Stop", isOn: $overNightStop)
                            .toggleStyle(.switch)
                        DatePicker("Arrive", selection: $location.dateArrive.toUnwrapped(defaultValue: Date()))
                        DatePicker("Depart", selection: $location.dateLeave.toUnwrapped(defaultValue: Date()))
                    } else {
                        DatePicker("Depart", selection: $location.dateLeave.toUnwrapped(defaultValue: Date()))
                        DatePicker("Arrive", selection: $location.dateArrive.toUnwrapped(defaultValue: Date()))
                    }
                }
                Section(header: Text("Notes")
                    .font(.headline)
                    .foregroundColor(.black)
                    .padding(EdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 0))
                ) {
                    TextField("notes", text: $location.notes.toUnwrapped(defaultValue: ""))
                }
                .textCase(nil)
            }
            
        }
        .onAppear() {
            startLocation = location.startLocation
            overNightStop = location.overNightStop
        }
        .onDisappear () {
            location.startLocation = startLocation
            location.overNightStop = overNightStop
            
            try? viewModel.moc.save()
            //globalVar.refreshMap.toggle()
            
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
    return EditDestinationView(location: location).environment(\.managedObjectContext, DataController.preview)
}
 


