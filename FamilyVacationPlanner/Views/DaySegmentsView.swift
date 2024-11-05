//
//  DaySegmentsView.swift
//  FamilyVacationPlanner
//
//  Created by David Steele on 9/3/24.
//

import SwiftUI

struct DaySegmentsView: View {
    @Environment(GlobalVariables.self) private var globalVars
    @State private var comprehensiveAndDailySegments: [DaySegments] = []
    @State private var selectedTabIndex: Int = 0
    @State var trip: Trip
    @State private var viewModel: ViewModel = ViewModel()
    @State private var states = [true, true, false, true, false]
    
    var body: some View {
        TabView(selection: $selectedTabIndex) {
            ForEach(comprehensiveAndDailySegments, id: \.id) { contentForTabView in
                VStack {
                    Section(header:
                                VStack {
                        Text(contentForTabView.formattedDateString)
                            .padding()
                    }
                            , content: {
                        List {
                            if contentForTabView.startLocationSet {
                                Text(contentForTabView.segments?.first?.startLocation?.name ?? "Unknown")
                            } else {
                                Button("Select Start Location") {
                                    globalVars.showSearchLocationSheet = true
                                    globalVars.locationType = .startLocation
                                }
                            }
                            if let segments = contentForTabView.segments {
                                ForEach(segments, id: \.self) { segment in
                                    if segment.segmentComplete {
                                        NavigationLink(value: segment.endLocation) {
                                            Group {
                                                if !segment.placeholder {
                                                    VStack {
                                                        HStack {
                                                            Text(String(segment.segmentIndex))
                                                            Text(segment.startLocation?.name ?? "")
                                                            Text(String(segment.startLocation?.locationIndex ?? 66))
                                                            Text("->")
                                                            Text(segment.endLocation?.name ?? "")
                                                            Text(String(segment.endLocation?.locationIndex ?? 66))
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
                                                                    .padding(.vertical, 8)
                                                                    .padding(.horizontal, 16)
                                                                    .background(RoundedRectangle(cornerRadius: 20)
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
                        .environment(\.editMode, .constant(.active))
                        .animation(.easeInOut, value: comprehensiveAndDailySegments)
                    })
                }
                .tag(contentForTabView.dayIndex)
            }
        }
        .tabViewStyle(.page)
        
        .navigationDestination(for: Location.self) {location in
            EditLocationView(location: location)
        }
        
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
    }
}

//#Preview {
//    DaySegmentsView()
//}
