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
        ZStack {
            Map(position: $position) {
                ForEach(viewModel.allMapInfo) {mapInfo in
                    Marker(mapInfo.markerLabelStart, coordinate: mapInfo.startingPoint ?? CLLocationCoordinate2D())
                    Marker(mapInfo.markerLabelEnd, coordinate: mapInfo.endingPoint ?? CLLocationCoordinate2D())
                    MapPolyline(mapInfo.route ?? MKRoute())
                        .stroke(.blue, lineWidth: 5)
                }
            }
            .animation(.easeInOut(duration: 1), value: selectedDetent)
            .animation(.easeInOut(duration: 1), value: position)
        }
        .sheet(isPresented: $showSheet) {
            TabView(selection: $selectedTabIndex) {
                ForEach(viewModel.comprehensiveAndDailySegments, id: \.id) { contentForTabView in
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
                                    print("old segmentIndex: \(viewModel.comprehensiveAndDailySegments[selectedTabIndex].segments[indices.last ?? 0].segmentIndex)")
                                    viewModel.comprehensiveAndDailySegments[selectedTabIndex].segments.move(fromOffsets: indices, toOffset: newOffset)

                                    print(indices.last ?? 0)
                                    print("destination \(newOffset)")
                                    print("selectedTabIndex: \(selectedTabIndex)")
                                    print("old segmentIndex: \(viewModel.comprehensiveAndDailySegments[selectedTabIndex].segments[indices.last ?? 0].segmentIndex)")
                                    viewModel.comprehensiveAndDailySegments[selectedTabIndex].segments[indices.last ?? 0].segmentIndex = newOffset
                                    print("new segmentIndex: \(viewModel.comprehensiveAndDailySegments[selectedTabIndex].segments[indices.last ?? 0].segmentIndex)")
                                    viewModel.fetchData(trip: trip)
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
                viewModel.fetchData(trip: trip)
                selectedTabIndex = viewModel.comprehensiveAndDailySegments[0].dayIndex
                updateMap()
            }
        }
        .sheet(isPresented: $isPresented, onDismiss: {
            viewModel.fetchData(trip: trip)
            selectedTabIndex = globalVar.selectedTabIndex
        }) {
            SearchDestinationView(trip: $trip, isPresented: $isPresented, locationType: $locationType, daySegments: .constant(viewModel.daySegmentsForFunction))
        }
        
        .onChange(of: selectedTabIndex) {
            globalVar.selectedTabIndex = selectedTabIndex
            updateMap()
        }
        
        .onChange(of: selectedDetent) {
            adjustRegion()
        }
    }
    
    @MainActor func move(source: IndexSet, destination: Int) {
        viewModel.comprehensiveAndDailySegments[selectedTabIndex].segments.move(fromOffsets: source, toOffset: destination)
        print("Source: \(source)")
        print("destination \(destination)")
        print("selectedTabIndex: \(selectedTabIndex)")
        viewModel.fetchData(trip: trip)
    }
    
    @MainActor func updateMap() {
        viewModel.daySegmentsForFunction = viewModel.comprehensiveAndDailySegments[selectedTabIndex].segments
        viewModel.getMapInfo()
        if viewModel.comprehensiveAndDailySegments[selectedTabIndex].segments[0].startLocation == viewModel.comprehensiveAndDailySegments[selectedTabIndex].segments[0].endLocation {
            singleLocation = true
        } else {
            singleLocation = false
        }
        print("SingleLocation: \(singleLocation)")
        adjustRegion()
        viewDate = viewModel.comprehensiveAndDailySegments[0].segments.first?.dayDate ?? Date()
        print("viewDate: \(viewDate)")
    }
    
    func adjustRegion() {
            let screenWidth = UIScreen.main.bounds.width
            let screenHeight = UIScreen.main.bounds.height
            
            
            // Calculate the bounding box for all annotations
            let latitudesEndPoint = viewModel.allMapInfo.map { $0.endingPoint!.latitude}
            let latitudesStartPoint = viewModel.allMapInfo.map { $0.startingPoint!.latitude}
            let latitudes: [CLLocationDegrees] = latitudesEndPoint + latitudesStartPoint
            let longitudesEndPoint = viewModel.allMapInfo.map { $0.endingPoint!.longitude}
            let longitudesStartPoint = viewModel.allMapInfo.map { $0.startingPoint!.longitude}
            let longitudes: [CLLocationDegrees] = longitudesEndPoint + longitudesStartPoint
            
            let minLat = latitudes.min()!
            let maxLat = latitudes.max()!
            let minLon = longitudes.min()!
            let maxLon = longitudes.max()!
            
            // Calculate the span
            let spanLat = (maxLat - minLat)
            let spanLon = (maxLon - minLon)
            
            // Calculate the center of the bounding box
            let centerLat = (minLat + maxLat) / 2
            let centerLon = (minLon + maxLon) / 2
            
            var adjustedCenterLat = centerLat
            var adjustedSpanLon = spanLon * 1.5
            var adjustedSpanLat = spanLat * 1.5
            
            if spanLon >= spanLat {
                let screenSpanLat = spanLon * screenHeight/screenWidth
                adjustedCenterLat = centerLat - screenSpanLat / 2 * 0.4
            }
            
            if spanLon < spanLat {
                adjustedCenterLat = centerLat - spanLat / 2
                adjustedSpanLon = spanLon / 0.4
                adjustedSpanLat = spanLat / 0.4
            }
        if selectedDetent == .fraction(0.5) {
            
            position = .region(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: adjustedCenterLat, longitude: centerLon), span: MKCoordinateSpan(latitudeDelta: adjustedSpanLat, longitudeDelta: adjustedSpanLon)))
            if singleLocation {
                position = .region(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: adjustedCenterLat - 0.03/4, longitude: centerLon), span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)))
            }
        } else {
            position = .automatic
            if singleLocation {
                position = .region(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: adjustedCenterLat, longitude: centerLon), span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)))
            }
        }
 
}
    
    
}

/*
 #Preview {
     let trip = Trip()
     return DayLocationsView(trip: trip)
 }
 */
 
      
 
