//
//  LocationSetUpView.swift
//  FamilyVacationPlanner
//
//  Created by David Steele on 9/6/24.
//

import CoreData
import MapKit
import SwiftUI

struct LocationSetUpView: View {
    
    @State private var viewModel: ViewModel = ViewModel()
    @Environment(GlobalVariables.self) var globalVars
    @Environment(DataModel.self) var dataModel
    @Environment(\.dismiss) var dismiss
    let locationMOC: Location
    @State private var placemark: MKPlacemark = MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0))
    @State private var locationType: LocationType = LocationType.pointOfInterest
    @State private var leaveDate: Date = Date()
    @State private var locationName: String = ""
    @State private var address: String = ""
    @State private var notes: String = ""
    @State private var overnightStop: Bool = false
    @State private var overnightsListSize: Int = 0
    @State private var numberOfNights: Int = 0
    @State private var locationIndex: Int = 0
    @State private var dayIndex: Int = 0
    @State private var locationPOI: LocationIcon?
    @State private var selectedPOI: LocationIcon?
    @State private var showPOISheet = false
    
    var body: some View {
        Form {
            Section("Location Name"){
                TextField("Location name", text: $locationName )
            }
            Section("Address"){
                Text(locationMOC.title ?? "Address is not known")
            }
            if viewModel.numberOfNightsLeft > 0 {
                Toggle("Overnight Stop", isOn: $overnightStop)
                    .toggleStyle(.switch)
                if overnightStop {
                    Picker("Leave", selection: $numberOfNights, content: {
                        ForEach(1..<viewModel.numberOfNightsLeft + 1, id: \.self) {
                            if $0 != 1 {
                                Text("\($0) Nights - \(viewModel.dayFromDayIndex + TimeInterval(($0 + 1) * 60 * 60 * 24))")
                            } else {
                                Text("\($0) Night - \(viewModel.dayFromDayIndex + TimeInterval(($0 + 1) * 60 * 60 * 24))")
                            }
                        }
                    })
                    .pickerStyle(.menu)
                    .onChange(of: numberOfNights) {
                        leaveDate = viewModel.dayFromDayIndex + TimeInterval((numberOfNights + 1) * 60 * 60 * 24)
                    }
                }
            }
            
            Section("Notes") {
                TextField("Notes", text: $notes )
            }
            
            Section("Location Category") {
                Button(action: {
                    showPOISheet = true
                }
                ) {
                    HStack {
                        Image(systemName: locationPOI?.poiSymbol ?? "map.marker")
                            .foregroundStyle(locationPOI?.poiColor ?? .black)
                        Text(locationPOI?.poiDisplayName ?? "No Location")
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            
            Section("Date Arrive") {
                Text("\(viewModel.dayFromDayIndex)")
            }
            Section("Date Leave") {
                DatePicker("Date Leave", selection: $leaveDate, displayedComponents: [.date])
            }
            
            Section("Location Index") {
                Text("\(locationMOC.locationIndex)")
            }
            Button("Save") {
                guard let trip = globalVars.selectedTrip else { return }
                locationMOC.name = locationName
                locationMOC.title = address
                locationMOC.poiCategory = locationPOI?.poiCategory
                if locationType == LocationType.startLocation {
                    locationMOC.dateLeave = trip.startDate
                    if !trip.oneWay {
                        locationMOC.dateArrive = trip.endDate
                    }
                }
                if overnightStop {
                    locationType = LocationType.overNightStop
                }
                if locationType == LocationType.overNightStop {
                    locationMOC.overNightStop = true
                    locationMOC.dateArrive = viewModel.dayFromDayIndex
                    locationMOC.numberOfNights = Int16(numberOfNights)
                    locationMOC.dateLeave = leaveDate
                }
                if locationType == LocationType.pointOfInterest {
                    locationMOC.dateArrive = viewModel.dayFromDayIndex
                    locationMOC.dateLeave = viewModel.dayFromDayIndex
                }
                trip.addToLocation(locationMOC)
                viewModel.getLocationIndex(location: locationMOC, dayIndex: dayIndex, locationIndex: locationIndex)
                globalVars.showSearchLocationSheet = false
                dismiss()
            }
        }

        .onAppear() {
            print("view appeared")
            locationName = locationMOC.name ?? ""
            notes = locationMOC.notes ?? ""
            locationPOI = LocationIcon(poiCategory: locationMOC.poiCategory)
            if locationMOC.startLocation {
                locationType = LocationType.startLocation
            }
            globalVars.selectedDetent = .fraction(0.5)
            locationIndex = globalVars.locationIndex
            dayIndex = globalVars.selectedTabIndex - 1
            if let trip = globalVars.selectedTrip {
                viewModel.getDates(trip: trip, dayIndex: dayIndex)
            }
            leaveDate = viewModel.dayFromDayIndex + TimeInterval(numberOfNights * 60 * 60 * 24)
        }
        .onChange (of: selectedPOI) {
            locationPOI = selectedPOI
        }
        .sheet(isPresented: $showPOISheet) {
            NavigationStack {
                List(CategoryGroup.allCases, id: \.self) { group in
                    NavigationLink(destination: POIPickerView(group: group, selectedCategory: $selectedPOI, showPOISheet: $showPOISheet)) {
                        Text(group.rawValue)
                    }
                }
                .navigationTitle("Select Group")
            }
        }
    }
}


#Preview {
    // Get the preview context with mock data already populated
    let context = DataController.preview
    
    // Fetch the first trip from the mock data
    let request: NSFetchRequest<Location> = Location.fetchRequest()
    var previewLocation: Location?
    
    do {
        let locations = try context.fetch(request)
        if let firstLocation = locations.first {
            previewLocation = firstLocation
        }
    } catch {
        fatalError("Failed to fetch preview location: \(error.localizedDescription)")
    }
    
    // Create DaySegmentsView with the fetched trip
    return Group {
        if let locationMOC = previewLocation {
            LocationSetUpView(locationMOC: locationMOC)
                .environment(\.managedObjectContext, context)
                .environment(DataModel())
                .environment(GlobalVariables())
        } else {
            Text("Failed to load preview location")
        }
    }
}
