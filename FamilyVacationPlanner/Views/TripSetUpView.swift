//
//  TripSetUpView.swift
//  FamilyVacationPlanner
//
//  Created by David Steele on 6/23/24.
//

import CoreData
import MapKit
import SwiftUI

struct TripSetUpView: View {
    
    @State private var viewModel: ViewModel = ViewModel()

    @Environment(DataModel.self) private var dataModel
    @Environment(GlobalVariables.self) private var globalVars
    let routeManager: RouteManager = RouteManager()
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
                                    Label(trip.tripName ?? "Unknown_oneWay", systemImage: "arrow.forward")
                                    :
                                    Label(trip.tripName ?? "Unknown_roundTrip", systemImage: "arrow.circlepath")
                                }
                                .font(.headline)
                            }
                        }
                    }
                    .onDelete(perform: removeTrip)
                    
                    Button(action: {
                        let tripTemplate = Trip(context: dataModel.moc)
                        tripTemplate.tripName = ""
                        tripTemplate.startDate = Date()
                        tripTemplate.endDate = Date()
                        tripTemplate.oneWay = false
                        path.append(tripTemplate)
                        editMode = true
                        newTrip = true
                        globalVars.selectedDetent = .large
                        globalVars.selectedDetent = .fraction(0.5)
                    }, label: {
                        Text("New Trip")
                    })
                }
                .onAppear {
                    editMode = false
                    globalVars.selectedDetent = .fraction(0.5)
                }
                
                Button(action: {
                    viewModel.generateMockData()
                }, label: {
                    Text("Generate Example Data")
                })
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
                    DaySegmentsView(trip: trip)
                        //.toolbar(.hidden, for: .navigationBar)
                }
            })
        }
    }
    
    func removeTrip(at offsets: IndexSet) {
        for index in offsets {
            let trip = trips[index]
            dataModel.moc.delete(trip)
            // Remove all route stored locally in cache
            routeManager.cleanCache(tripID: trip, activeSegments: [], tripDeleted: true)
        }
        do {
            try dataModel.moc.save()
        } catch {
            print("Core Data Error")
        }
    }
}


#Preview {
    TripSetUpView()
        .environment(\.managedObjectContext, DataController.preview)
        .environment(DataModel())
        .environment(GlobalVariables())
}
 

