//
//  TripSetUpView.swift
//  FamilyVacationPlanner
//
//  Created by David Steele on 6/23/24.
//

import MapKit
import SwiftUI

struct TripSetUpView: View {

    @Environment(DataModel.self) private var dataModel
    @Environment(GlobalVariables.self) private var globalVars
    
    @FetchRequest(sortDescriptors: [SortDescriptor(\.tripName)])
    var trips: FetchedResults<Trip>
    
    @State private var dateArrive: Date = Date()
    @State private var dateLeave: Date = Date()
    @State private var editMode: Bool = false
    @State private var newTrip: Bool = false
    @State private var oneWay: Bool = false
    @State private var path: NavigationPath = NavigationPath()
    @State private var startLocation: Location?
    @State private var tripName: String = ""

    var body: some View {
        NavigationStack(path: $path) {
            VStack(alignment: .leading) {
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
                    
                    Button(action: {
                        let trip = Trip(context: dataModel.moc)
                        trip.tripName = ""
                        trip.startDate = Date()
                        trip.endDate = Date()
                        trip.oneWay = false
                        path.append(trip)
                        editMode = true
                        newTrip = true
                        globalVars.selectedDetent = .large
                        globalVars.trip = trip
                    }, label: {
                        Text("New Trip")
                    })
                }
                .onAppear {
                    editMode = false
                    globalVars.selectedDetent = .fraction(0.5)
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
                    EditTripView(editMode: $editMode, newTrip: $newTrip, path: $path, trip: trip)
                } else {
                    DaySegmentsSetUpView()
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
            dataModel.moc.delete(trip)
        }
        do {
            try dataModel.moc.save()
        } catch {
            print("Core Data Error")
        }
    }
}


#Preview {
    TripSetUpView().environment(\.managedObjectContext, DataController.preview)
}
 

