//
//  AllDestinationsView.swift
//  FamilyVacationPlanner
//
//  Created by David Steele on 6/22/24.
//


import MapKit
import SwiftUI

struct AllDestinationsView: View {
    //@Environment(\.managedObjectContext) var moc
    @Environment(LocationsViewModel.self) private var viewModel
    @FetchRequest(sortDescriptors: [SortDescriptor(\.name)])
        var locations: FetchedResults<Location>

    @State var selectedDestination: Location = Location()

    
    var body: some View {
        NavigationStack {
            VStack {
                List {
                    ForEach(locations) { location in
                        NavigationLink(value: location) {
                            VStack(alignment: .leading) {
                                Text(location.name ?? "Unknown")
                                    .font(.headline)
                                Text(location.title ?? "Unknown")
                                    .font(.subheadline)
                                Text(location.dateArrive?.description ?? "Unknown")
                                Text("Overnight Stay: \(location.overNightStop)")
                            }
                        }
                    }
                    .onDelete(perform: removeLocation)
                }
                .navigationTitle("Edit Destination")
                .navigationBarTitleDisplayMode(.inline)
                .navigationDestination(for: Location.self) {location in
                    EditDestinationView(location: location)
                }
            }
        }
    }
    
    func removeLocation(at offsets: IndexSet) {
        for index in offsets {
            let location = locations[index]
            viewModel.moc.delete(location)
        }
        do {
            try viewModel.moc.save()
        } catch {
            print("Core Data Error")
        }
    }
}



#Preview {
    AllDestinationsView().environment(\.managedObjectContext, DataController.preview)
}
