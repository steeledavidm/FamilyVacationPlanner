//
//  DayLocationsView.swift
//  FamilyVacationPlanner
//
//  Created by David Steele on 7/15/24.
//

import CoreData
import MapKit
import SwiftUI

struct DayLocationsView: View {
    @Environment(LocationsViewModel.self) private var viewModel
    @Environment(GlobalVariables.self) private var globalVar
    @State var trip: Trip
    
    @State private var position: MapCameraPosition = .automatic
    @State private var locationType: LocationType = .pointOfInterest
    @State private var isPresented = false
    @State private var comprehensive: Bool = false
    @State private var viewDate: Date = Date()
    @State private var selectedTabIndex: Int = 0
    
    
    /*
    @FetchRequest(sortDescriptors: [SortDescriptor(\.dateLeave)])
        var locations: FetchedResults<Location>
    
    init(trip: Trip) {
        _locations = FetchRequest<Location>(sortDescriptors: [SortDescriptor(\.dateLeave)], predicate: NSPredicate(format: "%@ IN trip", trip))
        self.trip = trip
    }
     */
    
    
     

    

    
    var body: some View {
        TabView(selection: $selectedTabIndex) {
            ForEach(viewModel.comprehensiveAndDailySegments, id: \.id) { contentForTabView in
                VStack {
                   Map(position: $position) {
                       ForEach(viewModel.allMapInfo) {mapInfo in
                            Marker(mapInfo.markerLabelStart, coordinate: mapInfo.startingPoint ?? CLLocationCoordinate2D())
                            Marker(mapInfo.markerLabelEnd, coordinate: mapInfo.endingPoint ?? CLLocationCoordinate2D())
                           MapPolyline(mapInfo.route ?? MKRoute())
                                .stroke(.blue, lineWidth: 5)
                       }
                    }
                    Section(header: SectionHeaderView(date: viewDate , isPresented: $isPresented, locationType: $locationType, comprehensive: .constant(contentForTabView.comprehensive))) {
                        Button(
                            "update", action: {viewModel.fetchData(trip: trip)})
                        List {
                            ForEach(contentForTabView.segments, id: \.id) { segment in
                                VStack {
                                    HStack {
                                        Text(segment.dayString)
                                        Text(" : DaySegment \(contentForTabView.dayIndex)")
                                    }
                                    HStack {
                                        Text(segment.startLocation.name ?? "Start Location")
                                        Text("->")
                                        Text(segment.endLocation.name ?? "End Location")
                                        Button(
                                            "GO", action:  {
                                                let latitude = segment.endLocation.latitude
                                                let longitude = segment.endLocation.longitude
                                                let url = URL(string: "maps://?saddr=&daddr=\(latitude),\(longitude)")
                                                if UIApplication.shared.canOpenURL(url!) {
                                                      UIApplication.shared.open(url!, options: [:], completionHandler: nil)
                                                }
                                            }
                                        )
                                    }
                                }
                            }
                        }
                    }
                }
                .onAppear() {
                    viewModel.daySegmentsForFunction = contentForTabView.segments
                    viewModel.getMapInfo()
                    if contentForTabView.segments[0].startLocation == contentForTabView.segments[0].endLocation {
                        position = .region(MKCoordinateRegion(center: viewModel.allMapInfo.first?.startingPoint ?? CLLocationCoordinate2D(), span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)))
                        } else {
                            position = .automatic
                        }
                    
                    for segment in contentForTabView.segments {
                        print("dayDate: \(segment.dayDate)")
                    }
                    viewDate = contentForTabView.segments.first?.dayDate ?? Date()
                    print("viewDate: \(viewDate)")
                }
                .tag(contentForTabView.dayIndex)
            }
        }
        .tabViewStyle(.page)
        .onAppear {
            viewModel.fetchData(trip: trip)
            selectedTabIndex = viewModel.comprehensiveAndDailySegments[0].dayIndex
        }
        .sheet(isPresented: $isPresented, onDismiss: {
            viewModel.fetchData(trip: trip)
            selectedTabIndex = globalVar.selectedTabIndex
        }) {
            SearchDestinationView(trip: $trip, isPresented: $isPresented, locationType: $locationType, daySegments: .constant(viewModel.daySegmentsForFunction))
        }
        
        .onChange(of: selectedTabIndex) {
            globalVar.selectedTabIndex = selectedTabIndex
        }
         
    }
    
    
}

/*
 #Preview {
     let trip = Trip()
     return DayLocationsView(trip: trip)
 }
 */
 
      
 
