//
//  EditTripView.swift
//  FamilyVacationPlanner
//
//  Created by David Steele on 6/27/24.
//

import CoreData
import SwiftUI

struct EditTripView: View {
    @State var trip: Trip
    @State private var oneWayToggle: Bool = false
    @State private var isPresented: Bool = false
    @State private var locationType: LocationType = .startLocation
    
    @State private var oldStartLocation: Location? = nil
    @State private var filteredStartLocations: [Location?] = []
    @State private var startLocationsArray: [Location] = []
    @State private var selectedLocation: Location?
    //@Environment(\.managedObjectContext) var moc
    @Environment(LocationsViewModel.self) private var viewModel
    
    @FetchRequest(sortDescriptors: [SortDescriptor(\.name)], predicate: NSPredicate(format: "startLocation == true && primary == true"))
        var startLocations: FetchedResults<Location>
    
    @Binding var newTrip: Bool
    @Binding var editMode: Bool
    @Binding var path: NavigationPath
   

    var body: some View {
        VStack {
            VStack {
                Form {
                    Section("Trip Info") {
                        TextField("Trip Name", text: $trip.tripName.toUnwrapped(defaultValue: "Unknown"))
                        DatePicker("Trip Start", selection: $trip.startDate.toUnwrapped(defaultValue: Date()), displayedComponents: [.date])
                        DatePicker("Trip Finish", selection: $trip.endDate.toUnwrapped(defaultValue: Date()), displayedComponents: [.date])
                        Toggle("One Way", isOn: $oneWayToggle)
                            .toggleStyle(.switch)
                    }
                if newTrip {
                    Section("Select Start Location") {
                        List {
                            ForEach(startLocationsArray) { startLocation in
                                VStack {
                                    Text(startLocation.name ?? "Unknown")
                                    Text(startLocation.title ?? "Unknown")
                                }
                                .foregroundStyle(
                                    selectedLocation == startLocation ? Color.white : Color.black)
                                .listRowBackground(
                                    selectedLocation == startLocation ? Color.blue : Color.white
                                )
                                .onTapGesture {
                                    selectedLocation = startLocation
                                    let secondaryLocation = Location(context: viewModel.moc)
                                    secondaryLocation.id = UUID()
                                    secondaryLocation.name = startLocation.name
                                    secondaryLocation.title = startLocation.title
                                    secondaryLocation.subtitle = startLocation.subtitle
                                    secondaryLocation.latitude = startLocation.latitude
                                    secondaryLocation.longitude = startLocation.longitude
                                    secondaryLocation.startLocation = true
                                    secondaryLocation.overNightStop = false
                                    secondaryLocation.primary = false
                                    trip.addToLocation(secondaryLocation)
                                    try? viewModel.moc.save()
                                }
                            }
                        }
                        Button(action: {
                            isPresented = true
                            viewModel.moc.delete(oldStartLocation ?? Location())
                            do {
                                try viewModel.moc.save()
                            } catch {
                                print("Core Data Error")
                            }
                            
                            }, label: {
                            Text("Add New")

                        })
                    }
                    
                    Button(action: {
                        if selectedLocation != nil {
                            newTrip = false
                            path.append(trip)
                        }
                    }, label: {
                        Text("Add Trip")
                            .padding()
                            .background(Color(.blue))
                            .foregroundColor(.white)
                            .clipShape(.capsule)
                        }
                    )
                }
                    if !newTrip {
                        List {
                            VStack {
                                Text(oldStartLocation?.name ?? "Unknown")
                                Text(oldStartLocation?.title ?? "Unknown")
                            }
                            Button(action: {newTrip = true
                                   }, label: {
                                Text("Change Start Location")

                            })
                            
                        }
                        
                    }
                }
            }
            .onAppear() {
                oneWayToggle = trip.oneWay
                oldStartLocation = startLocations.filter{
                    $0.trip!.contains(trip)
                }.first
                print(oldStartLocation ?? "Location not found")
                startLocationsArray = startLocations.map { $0 }
                
                
                
                
                
                
                print("startLocations:")
                print(startLocations)
                print("filteredStartLocations")
                print(filteredStartLocations)
                
            }
            
            .onDisappear{
                trip.oneWay = oneWayToggle
                try? viewModel.moc.save()
                editMode = false
                
            }
        }
        .sheet(isPresented: $isPresented) {
            SearchDestinationView(trip: $trip, isPresented: $isPresented, locationType: $locationType, daySegments: .constant([Segment(segmentIndex: 0, dayDate: Date(), dayString: "", startLocation: Location(), endLocation: Location())]))
        }
    }
}
#Preview {
    let context = DataController.preview
    var trips: [Trip]
    let requestTrips: NSFetchRequest<Trip> = Trip.fetchRequest()
    do {
        trips = try context.fetch(requestTrips)
    } catch {
        let nserror = error as NSError
        fatalError("Error \(nserror): \(nserror.userInfo)")
    }
    let trip = trips[1]
    let newTrip = true
    let editMode = false
    let path = NavigationPath()
    //let selectedLocation = Location()
    return EditTripView(trip: trip, newTrip: .constant(newTrip), editMode: .constant(editMode), path: .constant(path)).environment(\.managedObjectContext, DataController.preview)
    
}
