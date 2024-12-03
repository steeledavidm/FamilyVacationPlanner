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
    @State private var selectedTabIndex: Int = 0
    var trip: Trip
    @State private var viewModel: ViewModel = ViewModel()
    @State private var states = [true, true, false, true, false]
    @State private var selectedLocation: Location?
    
    
    @FetchRequest(sortDescriptors: [SortDescriptor(\.dateLeave)])
        var locations: FetchedResults<Location>
    
    init(trip: Trip) {
        _locations = FetchRequest<Location>(sortDescriptors: [SortDescriptor(\.dateLeave)], predicate: NSPredicate(format: "%@ IN trip", trip))
        self.trip = trip
    }
    
    var body: some View {
        TabView(selection: $selectedTabIndex) {
            ForEach(viewModel.comprehensiveAndDailySegments, id: \.id) { contentForTabView in
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
                                    HStack{
                                        Image(systemName: "arrow.up.circle.fill")
                                            .foregroundStyle(.green)
                                            .font(.headline)
                                        Text(contentForTabView.segments?.first?.startLocation?.name ?? "Unknown")
                                            .foregroundStyle(.black)
                                            .font(.headline)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
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
                                                    HStack {
                                                        if !contentForTabView.comprehensive {
                                                            Button {
                                                                selectedLocation = segment.endLocation
                                                                globalVars.locationIndex = -99 // set to -99 to identify this was set from an existing location.
                                                                print(segment.endLocation?.name ?? "no segment selected")
                                                            } label: {
                                                                if let image = segment.poiIconEnd.poiSymbol {
                                                                    HStack {
                                                                        Image(systemName: image)
                                                                            .foregroundStyle(segment.poiIconEnd.poiColor)
                                                                            .font(.headline)
                                                                        Text(segment.endLocation?.name ?? "")
                                                                            .foregroundStyle(.black)
                                                                            .font(.headline)
                                                                            .frame(maxWidth: .infinity, alignment: .leading)
                                                                    }
                                                                    .labelStyle(.titleAndIcon)
                                                                }
                                                            }
                                                            Spacer()
                                                            
                                                        } else {
                                                            VStack(alignment: .leading) {
                                                                Label(title: {Text(segment.endLocation?.name ?? "") .font(.headline)}, icon: { Image(systemName: "bed.double.fill")
                                                                })
                                                            }
                                                            .frame(maxWidth: .infinity, alignment: .leading)
                                                            .onTapGesture(perform: {selectedTabIndex = index + 1
                                                                print("Selected tab index: \(selectedTabIndex)")
                                                            })
                                                            Spacer()
                                                        }
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
                                        if var segments = viewModel.comprehensiveAndDailySegments[selectedTabIndex].segments {
                                            // Get start location
                                            if viewModel.comprehensiveAndDailySegments[selectedTabIndex].startLocationSet {
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
                                                viewModel.comprehensiveAndDailySegments[selectedTabIndex].segments = segments
                                                Task {
                                                    try? await viewModel.saveLocationIndex(segments: segments, dayIndex: selectedTabIndex, trip: trip)
                                                }
                                            }
                                        }
                                    }
                                }
                            if !contentForTabView.comprehensive{
                                Button("Add Location") {
                                    globalVars.locationType = .pointOfInterest
                                    print("selected Tab Index: \(selectedTabIndex)")
                                    if let segments = contentForTabView.segments {
                                        for segmentIndex in segments {
                                            if let endLocation = segmentIndex.endLocation {
                                                let overNightStopSet = endLocation.overNightStop
                                                if !overNightStopSet{
                                                    globalVars.locationIndex = segmentIndex.segmentIndex + 1
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
                            }
                                //.environment(\.editMode, .constant(.active))
                        .animation(.easeInOut, value: viewModel.comprehensiveAndDailySegments)
                        })
                    }
                    .tag(contentForTabView.dayIndex)
                }
            }
            .tabViewStyle(.page)
            .onAppear() {
                print("Number of Locations: \(locations.count)")
                viewModel.locations = Array(locations)
                if viewModel.locations.isEmpty {
                    selectedTabIndex = 1
                }
                globalVars.selectTrip(trip)
                viewModel.setup(trip: trip)
                globalVars.selectedTabIndex = selectedTabIndex
                Task {
                    await viewModel.updateLocations()
                    globalVars.comprehensiveAndDailySegments = viewModel.comprehensiveAndDailySegments
                    if viewModel.comprehensiveAndDailySegments.count == 2 {
                        selectedTabIndex = 1
                    }
                }
            }
            .onChange(of: globalVars.locationUpdated) {
                print("updating locations")
                viewModel.locations = Array(locations)
                Task {
                    await viewModel.updateLocations()
                    globalVars.comprehensiveAndDailySegments = viewModel.comprehensiveAndDailySegments
                }
            }
            .onChange(of: selectedTabIndex) {
                print("selectedTabIndex changed to: \(selectedTabIndex)")
                globalVars.selectedTabIndex = selectedTabIndex
            }
            .sheet(item: $selectedLocation) { location in
                LocationSetUpView(location: location)
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
