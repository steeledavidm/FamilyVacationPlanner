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
    @Environment(GlobalVariables.self) private var globalVars
    @FocusState private var isFocusedTextField: Bool
    var backgroundColor: Color = Color.init(uiColor: . systemGray6)
    @State private var addressResult: AddressResult?
    @State private var results: [AnnotatedMapItem] = []
    @State private var selectedResult: MKMapItem?
    @State private var region = MKCoordinateRegion()
    @State private var annotationItems: [AnnotationItem] = []
    @State private var showLocationSetUpView = false
    @State private var searchText: String = ""
    @State private var currentLocation: CLPlacemark?
    @State private var recentList: [Location] = []
    @State private var overNightStop: Bool = false
    @State private var startLocation: Bool = false
    @State private var trip: Trip = Trip()
    @State private var locationType: LocationType = .startLocation
    @State private var daySegments: [Segment]?
    
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
                if isFocusedTextField {
                    List(searchModel.locationResult) { address in
                        VStack(alignment: .leading) {
                            Text(address.title)
                            Text(address.subtitle)
                                .font(.caption)
                        }
                        .onTapGesture {
                            isFocusedTextField = false
                            dataModel.plotRecentItems = false
                            addressResult = address
                            Task {
                                do {
                                    _ = try await dataModel.getPlace(from: addressResult ?? AddressResult(title: "201 Whitetail Ridge", subtitle: "201 Whitetail Ridge, Hudson, IA  50643, United States"))
                                }
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                    }
                    .background(backgroundColor)
                } else {
                    List(recentList) { recentLocation in
                        VStack(alignment: .leading) {
                            Text(recentLocation.name ?? "")
                                .font(.title3)
                            Text(recentLocation.title ?? "")
                        }
                        .onTapGesture {
                            let annotationItem = AnnotationItem(name: recentLocation.name ?? "", title: recentLocation.title ?? "", subtitle: recentLocation.subtitle ?? "", latitude: recentLocation.latitude, longitude: recentLocation.longitude)
                        }
                    }
                }
            }
        }
        .onAppear() {
            
            trip = globalVars.trip ?? Trip()
            locationType = globalVars.locationType ?? .startLocation
            dataModel.plotRecentItems = true
            
            switch locationType {
            case .startLocation:
                searchText = "Enter Trip Start Location"
                startLocation = true
                overNightStop = false
            case .endLocation:
                searchText = "Enter Trip End Location"
                startLocation = false
                overNightStop = false
            case .overNightStop:
                searchText = "Enter Overnight Stop"
                startLocation = false
                overNightStop = true
            case .pointOfInterest:
                searchText = "Enter Point Of Interest"
                startLocation = false
                overNightStop = false
            case .currentLocation:
                searchText = ""
            }
            
            Task {
                recentList = try await dataModel.populateRecentList(trip: trip)
                var annotationForMap: [AnnotationItem] = []
                for item in recentList {
                    annotationForMap.append(AnnotationItem(name: item.name ?? "", title: item.title ?? "", subtitle: item.subtitle ?? "", latitude: item.latitude, longitude: item.longitude))
                }
            }
        }
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


