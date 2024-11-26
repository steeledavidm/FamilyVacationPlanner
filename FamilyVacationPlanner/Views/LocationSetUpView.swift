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
    @State private var locationEditModel: LocationEditModel
    @Environment(GlobalVariables.self) var globalVars
    @Environment(\.dismiss) var dismiss
    @State private var placemark: MKPlacemark = MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0))
    @State private var locationType: LocationType = LocationType.pointOfInterest
    @State private var leaveDate: Date
    @State private var locationName: String = ""
    @State private var address: String = ""
    @State private var notes: String = ""
    @State private var overNightStop: Bool = false
    @State private var startLocation: Bool = false
    @State private var overnightsListSize: Int = 0
    @State private var numberOfNights: Int = 0
    @State private var locationIndex: Int = 0
    @State private var dayIndex: Int = 0
    @State private var locationPOI: LocationIcon?
    @State private var selectedPOI: LocationIcon?
    @State private var showPOISheet = false
    @State private var trip: Trip?
    
    // Init for editing
    init(location: Location) {
        _locationEditModel = State(wrappedValue: LocationEditModel(location: location))
        _leaveDate = State(initialValue: location.dateLeave ?? Date())
    }
    
    init(annotatedMapItem: AnnotatedMapItem, trip: Trip) {
        print("LocationSetUpView init with annotatedMapItem")
        _locationEditModel = State(wrappedValue: LocationEditModel(annotatedMapItem: annotatedMapItem, trip: trip))
        _leaveDate = State(initialValue: trip.startDate ?? Date())
        print("LocationEditModel name: \(LocationEditModel(annotatedMapItem: annotatedMapItem, trip: trip).name)")
    }
    
    var body: some View {
        Form {
            Section("Location Name"){
                TextField("Location name", text: $locationName )
            }
            Section("Address"){
                Text(locationEditModel.title)
            }
            if viewModel.numberOfNightsLeft > 0 {
                Toggle("Overnight Stop", isOn: $overNightStop)
                    .toggleStyle(.switch)
                if overNightStop {
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
                if !startLocation {
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
                } else {
                    HStack {
                        Image(systemName: "arrow.up.circle.fill")
                            .foregroundStyle(locationPOI?.poiColor ?? .black)
                        Text("Start Location")
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
                Text("\(locationEditModel.locationIndex)")
            }
            Button("Save") {
                guard let trip = globalVars.selectedTrip else { return }
                locationEditModel.name = locationName
                locationEditModel.title = address
                if let poiCategory = locationPOI?.poiCategory {
                    locationEditModel.poiCategory = poiCategory
                }
                if locationType == LocationType.startLocation {
                    locationEditModel.startLocation = true
                    if let startDate = trip.startDate {
                        locationEditModel.dateLeave = startDate
                    }
                    if !trip.oneWay {
                        if let endDate = trip.endDate {
                            locationEditModel.dateArrive = endDate
                        }
                    }
                }
                if overNightStop {
                    locationType = LocationType.overNightStop
                }
                if locationType == LocationType.overNightStop {
                    locationEditModel.overNightStop = true
                    locationEditModel.dateArrive = viewModel.dayFromDayIndex
                    locationEditModel.numberOfNights = Int16(numberOfNights)
                    locationEditModel.dateLeave = leaveDate
                }
                if locationType == LocationType.pointOfInterest {
                    locationEditModel.dateArrive = viewModel.dayFromDayIndex
                    locationEditModel.dateLeave = viewModel.dayFromDayIndex
                }
                locationEditModel.locationIndex = viewModel.getLocationIndex(startLocation: startLocation, overNightStop: overNightStop, dayIndex: dayIndex, locationIndex: locationIndex)
                globalVars.showSearchLocationSheet = false
                do {
                    try locationEditModel.save()
                    globalVars.locationUpdated.toggle()
                    dismiss()
                } catch {
                    print("error saving location: \(error)")
                }
            }
        }
 

        .onAppear() {
            print("view appeared")
            locationName = locationEditModel.name
            notes = locationEditModel.notes
            locationPOI = LocationIcon(poiCategory: locationEditModel.poiCategory)
            if locationEditModel.startLocation {
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
        if let location = previewLocation {
            LocationSetUpView(location: location)
                .environment(\.managedObjectContext, context)
                .environment(DataModel())
                .environment(GlobalVariables())
        } else {
            Text("Failed to load preview location")
        }
    }
}
