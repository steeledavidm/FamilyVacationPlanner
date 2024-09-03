//
//  SearchDestinationView.swift
//  FamilyVacationPlanner
//
//  Created by David Steele on 6/21/24.
//

import CoreData
import MapKit
import SwiftUI
import Foundation

struct SearchDestinationView : View {
    @State var searchModel = SearchModel()
    @Environment(DataModel.self) private var dataModel
    @FocusState private var isFocusedTextField: Bool
    var backgroundColor: Color = Color.init(uiColor: . systemGray6)
    @State private var addressResult: AddressResult?
    @State private var position: MapCameraPosition = .automatic
    @State private var results: [AnnotatedMapItem] = []
    @State private var selectedResult: MKMapItem?
    @State private var region = MKCoordinateRegion()
    @State private var annotationItems: [AnnotationItem] = []
    @State private var showAddDestinationView = false
    @State private var searchText: String = ""
    @State private var currentLocation: CLPlacemark?
    @State private var recentList: [Location] = []
    
    @Binding var trip: Trip
    @Binding var isPresented: Bool
    @Binding var locationType: LocationType
    @Binding var daySegments: [Segment]
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                TextField(searchText, text: $searchModel.searchText)
                    .padding()
                    .autocorrectionDisabled()
                    .focused($isFocusedTextField)
                    .font(.title)
                    .onChange(of: searchModel.searchText) {
                        searchModel.completer.queryFragment = searchModel.searchText
                    }
                    .background(Color.init(uiColor: . systemBackground))
                    .overlay {
                        ClearButton(text: $searchModel.searchText)
                            .padding(.trailing)
                            .padding(.top, 8)
                    }
                    .onAppear {
                        isFocusedTextField = true
                    }
                
                List(searchModel.locationResult) { address in
                    VStack(alignment: .leading) {
                        Text(address.title)
                        Text(address.subtitle)
                            .font(.caption)
                    }
                    .onTapGesture {
                        isFocusedTextField = false
                        addressResult = address
                        Task {
                            do{
                                _ = try await getPlace(from: addressResult ?? AddressResult(title: "201 Whitetail Ridge", subtitle: "201 Whitetail Ridge, Hudson, IA  50643, United States"))
                                showAddDestinationView = true
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
                .background(backgroundColor)
                
                List(recentList) { recentLocation in
                    VStack(alignment: .leading) {
                        Text(recentLocation.name ?? "")
                        Text(recentLocation.title ?? "")
                    }}
                
                .navigationDestination(isPresented: $showAddDestinationView, destination: {AddDestinationView(results: $results, trip: $trip, isPresented: $isPresented, locationType: $locationType, daySegments: $daySegments)
                })
            }
        }
        .onAppear() {
            switch locationType {
            case .startLocation:
                searchText = "Enter Trip Start Location"
            case .endLocation:
                searchText = "Enter Trip End Location"
            case .overNightStop:
                searchText = "Enter Overnight Stop"
            case .pointOfInterest:
                searchText = "Enter Point Of Interest"
            case .currentLocation:
                searchText = ""
            }
            
            //recentList = dataModel.populateRecentList(trip: trip)
            
//            
//            
//            dataModel.getCurrentLocation(completionHandler: { currentLocation in
//                print("name: \(String(describing: currentLocation?.name))")
//                print("address: \(String(describing: currentLocation?.thoroughfare))")
//            })
            
        }
    }
        
        
    func getPlace(from address: AddressResult) async throws -> [AnnotatedMapItem] {
        let request = MKLocalSearch.Request()
        let title = address.title
        let subtitle = address.subtitle
        results = []
        
        request.naturalLanguageQuery = subtitle.contains(title)
        ? subtitle : title + ", " + subtitle

        let response = try await MKLocalSearch(request: request).start()
        await MainActor.run {
            annotationItems = response.mapItems.map {
                AnnotationItem(
                    name: $0.name ?? "",
                    title: $0.placemark.title ?? "",
                    subtitle: $0.placemark.subtitle ?? "",
                    latitude: $0.placemark.coordinate.latitude,
                    longitude: $0.placemark.coordinate.longitude
                )
            }
            
            region = response.boundingRegion
            position = .region(region)
            let resultsMKMapItem = response.mapItems
            for result in resultsMKMapItem {
                results.append(AnnotatedMapItem(item: result))
            }
        }
        return results
    }
}

/*
#Preview {
    let context = DataController.preview
    let trips: [Trip]
    let requestTrips: NSFetchRequest<Trip> = Trip.fetchRequest()
    do {
        trips = try context.fetch(requestTrips)
    } catch {
        let nserror = error as NSError
        fatalError("Error \(nserror): \(nserror.userInfo)")
    }
    let isPresented = false
    let trip = trips[0]
    let locationType: LocationType = .startLocation
    let daySegments = [Segment(dayDate: Date(), dayString: "Today", startLocation: Location(), endLocation: Location())]
    return SearchDestinationView(trip: trip, isPresented: isPresented, locationType: locationType, daySegments: daySegments).environment(\.managedObjectContext, DataController.preview)
}
 
 */


