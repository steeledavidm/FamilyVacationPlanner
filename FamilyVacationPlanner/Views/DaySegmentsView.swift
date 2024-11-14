//
//  DaySegmentsView.swift
//  FamilyVacationPlanner
//
//  Created by David Steele on 9/3/24.
//

import CoreData
import SwiftUI

struct DaySegmentsView: View {
    @Environment(GlobalVariables.self) private var globalVars
    @Environment(DataModel.self) private var dataModel
    @State private var comprehensiveAndDailySegments: [DaySegments] = []
    @State private var selectedTabIndex: Int = 0
    @ObservedObject var trip: Trip
    @State private var viewModel: ViewModel = ViewModel()
    @State private var states = [true, true, false, true, false]
    @State private var selectedLocation: Location?
    
    var body: some View {
        TabView(selection: $selectedTabIndex) {
            ForEach(comprehensiveAndDailySegments, id: \.id) { contentForTabView in
                VStack {
                    Section(header:
                        VStack {
                            Text(contentForTabView.formattedDateString)
                            .padding(.top, 15)
                            HStack{
                                Label(Duration.seconds(contentForTabView.totalTime).formatted(.time(pattern: .hourMinute)),
                                      systemImage: "clock")
                                .font(.subheadline)
                                Label(
                                    title: { Text("\(Measurement(value: contentForTabView.totalDistance, unit: UnitLength.meters).converted(to: .miles).value, specifier: "%.0f") mi")
                                        .font(.subheadline) },
                                    icon: { Image(systemName: "point.topleft.down.curvedto.point.bottomright.up") }
                                )
                            }
                        }
                            , content: {
                        List {
                            if contentForTabView.startLocationSet {
                                HStack {
                                    Label(contentForTabView.segments?.first?.startLocation?.name ?? "Unknown", systemImage: "arrow.up.circle")
                                    Spacer()
                                    if !contentForTabView.comprehensive {
                                        Button(action:  {
                                            let latitude = contentForTabView.segments?.first?.endLocation?.latitude ?? 0.0
                                            let longitude = contentForTabView.segments?.first?.endLocation?.longitude ?? 0.0
                                            let url = URL(string: "maps://?saddr=&daddr=\(latitude),\(longitude)")
                                            if UIApplication.shared.canOpenURL(url!) {
                                                UIApplication.shared.open(url!, options: [:], completionHandler: nil)
                                            }
                                        }
                                        ) {
                                            Text("GO")
                                                .font(.title2)
                                                .fontWeight(.bold)
                                                .foregroundColor(.white)
                                                .padding(.vertical, 10)
                                                .padding(.horizontal, 8)
                                                .background(RoundedRectangle(cornerRadius: 10)
                                                    .fill(Color.green)
                                                    .shadow(color: Color.green.opacity(0.3), radius: 10, x: 0, y: 5)
                                                )
                                            
                                        }
                                        .contentShape(Rectangle())
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                            } else {
                                Button("Select Start Location") {
                                    globalVars.showSearchLocationSheet = true
                                    globalVars.locationType = .startLocation
                                }
                            }
                            if let segments = contentForTabView.segments {
                                ForEach(segments.indices, id: \.self) { index in
                                    let segment = segments[index]
                                    if segment.segmentComplete && !segment.placeholder && (segment.endLocation != segment.startLocation) {
                                        Group {
                                            VStack(alignment: .leading) {
                                                if contentForTabView.comprehensive {
                                                    Text(segment.dayDate.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day().year()))
                                                        .font(.subheadline)
                                                        .padding()
                                                }
                                                HStack {
                                                    VStack(alignment: .leading, spacing: 8) {
                                                        Label(Duration.seconds(segment.time ?? 0).formatted(.time(pattern: .hourMinute)),
                                                              systemImage: "clock")
                                                        .font(.subheadline)
                                                        Label(
                                                            title: { Text("\(Measurement(value: segment.distance ?? 0, unit: UnitLength.meters).converted(to: .miles).value, specifier: "%.0f") mi")
                                                                .font(.subheadline) },
                                                            icon: { Image(systemName: "point.topleft.down.curvedto.point.bottomright.up") }
                                                        )
                                                    }
                                                    .frame(alignment: .leading)
                                                    HStack {
                                                        if !contentForTabView.comprehensive {
                                                            Button {
                                                                selectedLocation = segment.endLocation
                                                                print(segment.endLocation?.name ?? "no segment selected")
                                                            } label: {
                                                                Text(segment.endLocation?.name ?? "")
                                                            }
                                                            Spacer()
                                                            Button(action:  {
                                                                let latitude = segment.endLocation?.latitude ?? 0.0
                                                                let longitude = segment.endLocation?.longitude ?? 0.0
                                                                let url = URL(string: "maps://?saddr=&daddr=\(latitude),\(longitude)")
                                                                if UIApplication.shared.canOpenURL(url!) {
                                                                    UIApplication.shared.open(url!, options: [:], completionHandler: nil)
                                                                }
                                                            }
                                                            ) {
                                                                Text("GO")
                                                                    .font(.title2)
                                                                    .fontWeight(.bold)
                                                                    .foregroundColor(.white)
                                                                    .padding(.vertical, 10)
                                                                    .padding(.horizontal, 8)
                                                                    .background(RoundedRectangle(cornerRadius: 10)
                                                                        .fill(Color.green)
                                                                        .shadow(color: Color.green.opacity(0.3), radius: 10, x: 0, y: 5)
                                                                    )
                                                                
                                                            }
                                                            .contentShape(Rectangle())
                                                            .buttonStyle(PlainButtonStyle())
                                                        } else {
                                                            VStack(alignment: .leading) {
                                                                Label(title: {Text(segment.endLocation?.name ?? "") .font(.headline)}, icon: { Image(systemName: "bed.double")
                                                                })
                                                            }
                                                            .frame(maxWidth: .infinity, alignment: .leading)
                                                            .onTapGesture(perform: {selectedTabIndex = index + 1
                                                                print("Selected tab index: \(selectedTabIndex)")
                                                            })
                                                            Spacer()
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                        .moveDisabled(segment.endLocation?.overNightStop ?? false || segment.placeholder)
                                    }
                                }
                                //.onDelete(perform: viewModel.removeSegment)
                                    .onMove { indices, newOffset in
                                        var startLocation: Location?
                                        if var segments = comprehensiveAndDailySegments[selectedTabIndex].segments {
                                            // Get start location
                                            if comprehensiveAndDailySegments[selectedTabIndex].startLocationSet {
                                                startLocation = segments[0].startLocation
                                            }
                                            
                                            segments.move(fromOffsets: indices, toOffset: newOffset)
                                            withAnimation {
                                                for (index, _) in segments.enumerated() {
                                                    segments[index].segmentIndex = index
                                                }
                                                if let startLocation = startLocation {
                                                    segments[0].startLocation = startLocation
                                                }
                                                comprehensiveAndDailySegments[selectedTabIndex].segments = segments
                                                Task {
                                                    try? await viewModel.saveLocationIndex(segments: segments, dayIndex: selectedTabIndex, trip: trip)
                                                }
                                            }
                                        }
                                    }
                                }
                                Button("Add Location") {
                                    globalVars.locationType = .pointOfInterest
                                    print("selected Tab Index: \(selectedTabIndex)")
                                    if let segments = contentForTabView.segments {
                                        for segmentIndex in segments {
                                            if let endLocation = segmentIndex.endLocation {
                                                let overNightStopSet = endLocation.overNightStop
                                                if !overNightStopSet{
                                                    globalVars.locationIndex = segmentIndex.segmentIndex
                                                    globalVars.locationType = .pointOfInterest
                                                } else {
                                                    globalVars.locationType = .endLocation
                                                }
                                            }
                                        }
                                    }
                                    globalVars.showSearchLocationSheet = true
                                }
                            }
                                //.environment(\.editMode, .constant(.active))
                                .animation(.easeInOut, value: comprehensiveAndDailySegments)
                        })
                    }
                    .tag(contentForTabView.dayIndex)
                }
            }
            .tabViewStyle(.page)
            .onAppear() {
                globalVars.selectedTabIndex = 0
                globalVars.trip = trip
                Task {
                    try? await viewModel.fetchData(trip: trip)
                    comprehensiveAndDailySegments = viewModel.comprehensiveAndDailySegments
                }
            }
            .onChange(of: selectedTabIndex) {
                print("selectedTabIndex changed to: \(selectedTabIndex)")
                globalVars.selectedTabIndex = selectedTabIndex
            }
            .onChange(of: globalVars.locationAdded) {
                Task {
                    print("updating locations")
                    try? await viewModel.fetchData(trip: trip)
                    comprehensiveAndDailySegments = viewModel.comprehensiveAndDailySegments
                    print("locations updated")
                }
            }
            .onChange(of: comprehensiveAndDailySegments) {
                globalVars.comprehensiveAndDailySegments = comprehensiveAndDailySegments
            }
            .onChange(of: viewModel.comprehensiveAndDailySegments) {
                print("in change of viewModel.comprehensiveAndDailySegments")
                comprehensiveAndDailySegments = viewModel.comprehensiveAndDailySegments
            }
            .sheet(item: $selectedLocation) { location in
                EditLocationView(location: location)
                    .environment(\.managedObjectContext, dataModel.moc)
            }
        }
    }

#Preview {
    // Get the preview context with mock data already populated
    let context = DataController.preview
    
    // Fetch the first trip from the mock data
    let request: NSFetchRequest<Trip> = Trip.fetchRequest()
    var previewTrip: Trip?
    
    do {
        let trips = try context.fetch(request)
        if let firstTrip = trips.first {
            previewTrip = firstTrip
        }
    } catch {
        fatalError("Failed to fetch preview trip: \(error.localizedDescription)")
    }
    
    // Create DaySegmentsView with the fetched trip
    return Group {
        if let trip = previewTrip {
            DaySegmentsView(trip: trip)
                .environment(\.managedObjectContext, context)
                .environment(DataModel())
                .environment(GlobalVariables())
        } else {
            Text("Failed to load preview trip")
        }
    }
}
