//
//  DaySegmentsView.swift
//  FamilyVacationPlanner
//
//  Created by David Steele on 9/3/24.
//

import SwiftUI

struct DaySegmentsView: View {
    //@Environment(DataModel.self) private var dataModel
    @Environment(GlobalVariables.self) private var globalVars
    @State private var comprehensiveAndDailySegments: [DaySegments] = []
    @State private var selectedTabIndex: Int = 0
    @State var trip: Trip
    @State private var viewModel: ViewModel = ViewModel()
    
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
                                    if !segment.placeholder {
                                        VStack {
                                            HStack {
                                                Text(String(segment.segmentIndex))
                                                Text(segment.endLocation?.name ?? "End Location")
                                                Spacer()
                                                Button(
                                                    "GO", action:  {
                                                        let latitude = segment.endLocation?.latitude ?? 0.0
                                                        let longitude = segment.endLocation?.longitude ?? 0.0
                                                        let url = URL(string: "maps://?saddr=&daddr=\(latitude),\(longitude)")
                                                        if UIApplication.shared.canOpenURL(url!) {
                                                            UIApplication.shared.open(url!, options: [:], completionHandler: nil)
                                                        }
                                                    }
                                                )
                                            }
                                        }
                                    } else {
                                        Button("Add Stop") {
                                            //globalVars.showSearchLocationSheet = true
                                            //globalVars.locationType = .pointOfInterest
                                            globalVars.locationIndex = segment.segmentIndex
                                        }
                                    }
                                        //.moveDisabled(segment.endLocation?.overNightStop)
                                }
                                .onMove { indices, newOffset in
                                    if var segments = comprehensiveAndDailySegments[selectedTabIndex].segments {
                                        segments.move(fromOffsets: indices, toOffset: newOffset)
                                    
                                        for (index, _) in segments.enumerated() {
                                            comprehensiveAndDailySegments[selectedTabIndex].segments?[index].segmentIndex = segments[index].segmentIndex
                                        }
                                        comprehensiveAndDailySegments[selectedTabIndex].segments?.sort {
                                            $0.segmentIndex < $1.segmentIndex
                                        }
                                    }
                                    
                                    
//
//                                   
//                                    
//
//    
//    
//                                
//                                        
//                                
//                                    //viewModel.fetchData(trip: trip)
                                }
                            }
                        }
                        .environment(\.editMode, .constant(.active))
                    })
                }
                .tag(contentForTabView.dayIndex)
            }
        }
        .tabViewStyle(.page)
        
        .onAppear() {
            globalVars.selectedTabIndex = 0
            globalVars.trip = trip
            viewModel.fetchData(trip: trip)
            comprehensiveAndDailySegments = viewModel.comprehensiveAndDailySegments
        }
        .onChange(of: selectedTabIndex) {
            print("selectedTabIndex changed to: \(selectedTabIndex)")
            globalVars.selectedTabIndex = selectedTabIndex
        }
        .onChange(of: globalVars.locationAdded) {
            viewModel.fetchData(trip: trip)
            comprehensiveAndDailySegments = viewModel.comprehensiveAndDailySegments
        }
    }
}

//#Preview {
//    DaySegmentsView()
//}
