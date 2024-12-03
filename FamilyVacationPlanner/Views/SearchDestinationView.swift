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
    @Environment(\.dismiss) var dismiss
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
    //@State private var recentList: [Location] = []
    @State private var overNightStop: Bool = false
    @State private var startLocation: Bool = false
    @State private var locationType: LocationType = .startLocation
    @State private var daySegments: [Segment]?
    @State private var selectedLocation: Location?
    
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
                            globalVars.displaySearchedLocations = true
                            addressResult = address
                            Task {
                                do {
                                    _ = try await dataModel.getPlace(from: addressResult ?? AddressResult(title: "title", subtitle: "subtitle"))
                                }
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                    }
                    .background(backgroundColor)
                } else {
                    List(dataModel.recentList) { recentLocation in
                        VStack(alignment: .leading) {
                            Text(recentLocation.name ?? "")
                                .font(.title3)
                            Text(recentLocation.title ?? "")
                        }
                        .onTapGesture {
                            if recentLocation.name == "Current Location" {
                                selectedLocation = recentLocation
                            }
                            else {
                                var location = Location(context: dataModel.moc)
                                location = recentLocation
                                location.id = UUID()
                                location.primary = false
                                recentLocation.primary = true
                                if globalVars.locationType == LocationType.startLocation {
                                    location.startLocation = true
                                }
                                if globalVars.locationType == LocationType.overNightStop {
                                    location.overNightStop = true
                                }
                                globalVars.selectedTrip?.addToLocation(location)
                                try? dataModel.moc.save()
                                dismiss()
                            }
                        }
                    }
                }
            }
        }
        .onDisappear() {
            print("onDisappear")
            globalVars.displaySearchedLocations = false
        }
        .onAppear() {
            //recentList = dataModel.recentList
            locationType = globalVars.locationType ?? .startLocation
            dataModel.plotRecentItems = true
            globalVars.displaySearchedLocations = true
            
            switch locationType {
            case .startLocation:
                searchText = "Trip Start Address"
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
                searchText = "Enter Address"
                startLocation = false
                overNightStop = false
            case .currentLocation:
                searchText = ""
            }
            
            Task {
                guard let trip = globalVars.selectedTrip else { return }
                try await dataModel.populateRecentList(trip: trip)
                var annotationForMap: [AnnotationItem] = []
                for item in dataModel.recentList {
                    annotationForMap.append(AnnotationItem(name: item.name ?? "", title: item.title ?? "", subtitle: item.subtitle ?? "", latitude: item.latitude, longitude: item.longitude))
                }
            }
        }
        .sheet(item: $selectedLocation) { location in
            LocationSetUpView(location: location)
        }
    }
}


#Preview {
    SearchDestinationView()
        .environment(\.managedObjectContext, DataController.preview)
        .environment(DataModel())
        .environment(GlobalVariables())
}


