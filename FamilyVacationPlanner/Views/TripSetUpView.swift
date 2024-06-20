//
//  TripSetUpView.swift
//  FamilyVacationPlanner
//
//  Created by David Steele on 6/23/24.
//

import MapKit
import SwiftUI

struct TripSetUpView: View {
    //@Environment(\.managedObjectContext) var moc
    @Environment(LocationsViewModel.self) private var viewModel
    
    @FetchRequest(sortDescriptors: [SortDescriptor(\.tripName)])
    var trips: FetchedResults<Trip>
    
    @State private var tripName: String = ""
    @State private var oneWay: Bool = false
    @State private var dateLeave: Date = Date()
    @State private var dateArrive: Date = Date()
    var selection: MKMapItem?
    @State private var startLocation: Location?
    @State private var test: String = "test"
    
    @State var editMode: Bool = false
    
    @FocusState private var isFocused: Bool
    @State private var path: NavigationPath = NavigationPath()
    @State private var newTrip: Bool = false
    
    var body: some View {
        NavigationStack(path: $path) {
            VStack(alignment: .leading) {
                Section("Trips") {
                    List {
                        ForEach(trips) { trip in
                            NavigationLink(value: trip) {
                                VStack(alignment: .leading) {
                                    HStack {
                                        trip.oneWay ?
                                        Label(trip.tripName ?? "Unknown", systemImage: "arrow.forward")
                                        :
                                        Label(trip.tripName ?? "Unknown", systemImage: "arrow.circlepath")
                                    }
                                    .font(.headline)
                                }
                            }
                        }
                        .onDelete(perform: removeTrip)
                    }
                }
                
                
                VStack {
                    Button(action: {
                        let trip = Trip(context: viewModel.moc)
                        trip.tripName = ""
                        trip.startDate = Date()
                        trip.endDate = Date()
                        trip.oneWay = false
                        path.append(trip)
                        editMode = true
                        newTrip = true
                    }, label: {
                        Text("New Trip")
                            .padding()
                            .background(Color(.blue))
                            .foregroundColor(.white)
                            .clipShape(.capsule)
                    })
                }
            }
            .navigationTitle("Select Trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button(action: {
                    editMode = true
                }) {
                    Text("Edit")
                }
                .padding(.horizontal)
                .background(editMode ? Color(.blue) : Color(.clear))
                .foregroundColor(editMode ? .white : .blue)
                .clipShape(.capsule)
            }
            .navigationDestination(for: Trip.self, destination: {trip in
                if editMode {
                    EditTripView(trip: trip, newTrip: $newTrip, editMode: $editMode, path: $path)
                } else {
                    TripOverviewView(trip: trip)
                }
            })
            .navigationDestination(for: Location.self) {location in
                EditDestinationView(location: location)
            }
        }
    }



    
    func removeTrip(at offsets: IndexSet) {
        for index in offsets {
            let trip = trips[index]
            viewModel.moc.delete(trip)
        }
        do {
            try viewModel.moc.save()
        } catch {
            print("Core Data Error")
        }
    }
}


#Preview {
    TripSetUpView().environment(\.managedObjectContext, DataController.preview)
}
 

