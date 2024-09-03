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
    @Environment(DataModel.self) private var dataModel
    @Environment(GlobalVariables.self) private var globalVar
    @State var trip: Trip
    
    @State private var position: MapCameraPosition = .automatic
    @State private var locationType: LocationType = .pointOfInterest
    @State private var isPresented = false
    @State private var comprehensive: Bool = false
    @State private var viewDate: Date = Date()
    @State private var selectedTabIndex: Int = 0
    @State private var showSheet = true
    @State private var selectedDetent: PresentationDetent = .fraction(0.5)
    @State private var viewAppeared = false
    @State private var singleLocation = false
    

    
    
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
                ForEach(dataModel.comprehensiveAndDailySegments, id: \.id) { contentForTabView in
                    VStack {
                        Section(header: SectionHeaderView(date: viewDate , isPresented: $isPresented, locationType: $locationType, comprehensive: .constant(contentForTabView.comprehensive))) {
                            List {
                                ForEach(contentForTabView.segments, id: \.id) { segment in
                                    VStack {
                                        HStack {
                                            Text(segment.dayString)
                                            //Text(" : DaySegment \(contentForTabView.dayIndex)")
                                            Text("index: \(segment.segmentIndex)")
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
                                    //.moveDisabled(segment.startLocation == true || segment.endLocation == true)
                                }
                                .onMove { indices, newOffset in
                                    print("old segmentIndex: \(dataModel.comprehensiveAndDailySegments[selectedTabIndex].segments[indices.last ?? 0].segmentIndex)")
                                    dataModel.comprehensiveAndDailySegments[selectedTabIndex].segments.move(fromOffsets: indices, toOffset: newOffset)

                                    print(indices.last ?? 0)
                                    print("destination \(newOffset)")
                                    print("selectedTabIndex: \(selectedTabIndex)")
                                    print("old segmentIndex: \(dataModel.comprehensiveAndDailySegments[selectedTabIndex].segments[indices.last ?? 0].segmentIndex)")
                                    dataModel.comprehensiveAndDailySegments[selectedTabIndex].segments[indices.last ?? 0].segmentIndex = newOffset
                                    print("new segmentIndex: \(dataModel.comprehensiveAndDailySegments[selectedTabIndex].segments[indices.last ?? 0].segmentIndex)")
                                    dataModel.fetchData(trip: trip)
                                }
                            }
                            .environment(\.editMode, .constant(.active))
                        }
                    }
                    .tag(contentForTabView.dayIndex)
                }
                .interactiveDismissDisabled()
                .presentationDetents([.fraction(0.5), .fraction(0.9), .fraction(0.1)], selection: $selectedDetent)
                .presentationBackgroundInteraction(.enabled)
            }
            .tabViewStyle(.page)
            .onAppear {
                globalVar.selectedTabIndex = 0
                dataModel.fetchData(trip: trip)
                selectedTabIndex = dataModel.comprehensiveAndDailySegments[0].dayIndex
            }
        
        .sheet(isPresented: $isPresented, onDismiss: {
            dataModel.fetchData(trip: trip)
            selectedTabIndex = globalVar.selectedTabIndex
        }) {
            SearchDestinationView(trip: $trip, isPresented: $isPresented, locationType: $locationType, daySegments: .constant(dataModel.daySegmentsForFunction))
        }
        
        .onChange(of: selectedTabIndex) {
            globalVar.selectedTabIndex = selectedTabIndex
            print(dataModel.comprehensiveAndDailySegments.count)
        }
    }
    
    @MainActor func move(source: IndexSet, destination: Int) {
        dataModel.comprehensiveAndDailySegments[selectedTabIndex].segments.move(fromOffsets: source, toOffset: destination)
        print("Source: \(source)")
        print("destination \(destination)")
        print("selectedTabIndex: \(selectedTabIndex)")
        dataModel.fetchData(trip: trip)
    }
}

/*
 #Preview {
     let trip = Trip()
     return DayLocationsView(trip: trip)
 }
 */
 
      
 
