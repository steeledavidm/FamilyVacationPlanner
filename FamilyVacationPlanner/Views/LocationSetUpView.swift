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
    //@Environment(LocationEditModel.self) private var locationEditModel
    @Bindable private var locationEditModel: LocationEditModel
    @Environment(GlobalVariables.self) var globalVars
    @Environment(\.dismiss) var dismiss
    @State private var placemark: MKPlacemark = MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0))
    @State private var locationType: LocationType = LocationType.pointOfInterest
    @State private var leaveDate: Date
    @State private var overNightStop: Bool = false
    @State private var startLocation: Bool = false
    @State private var overnightsListSize: Int = 0
    @State private var numberOfNights: Int = 0
    @State private var locationIndex: Int = 0
    @State private var dayIndex: Int = 0
    @State private var selectedPOI: LocationIcon?
    @State private var showPOISheet = false
    @State private var trip: Trip?
    @State private var localName: String
    
    // Init for editing
    init(location: Location) {
        print("in the Location initializer")
        let editModel = LocationEditModel(location: location)
        self._leaveDate = State(initialValue: location.dateLeave ?? Date())
        self._locationEditModel = Bindable(editModel)
        self._localName = State(initialValue: editModel.name)
    }
    
    init(locationSetUp: LocationSetUp, trip: Trip) {
        print("LocationSetUpView init with locationSetUp")
        let editModel = LocationEditModel(locationSetUp: locationSetUp, trip: trip)
        self._leaveDate = State(initialValue: trip.startDate ?? Date())
        self._locationEditModel = Bindable(editModel)
        self._localName = State(initialValue: editModel.name)
    }
    
    var body: some View {
        Form {
            Section("Location Name"){
                TextField("Location name", text: $localName)
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
                TextField("Notes", text: $locationEditModel.notes )
            }
            
            Section("Location Category") {
                if !startLocation {
                    Button(action: {
                        showPOISheet = true
                    }
                    ) {
                        HStack {
                            Image(systemName: locationEditModel.locationPOI?.poiSymbol ?? "map.marker")
                                .foregroundStyle(locationEditModel.locationPOI?.poiColor ?? .black)
                            Text(locationEditModel.locationPOI?.poiDisplayName ?? "No Location")
                                .foregroundStyle(.black)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                } else {
                    HStack {
                        Image(systemName: "arrow.up.circle.fill")
                            .foregroundStyle(locationEditModel.locationPOI?.poiColor ?? .black)
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
                globalVars.locationFromMap = nil
                globalVars.selectedDetent = .fraction(0.5)
                locationEditModel.name = localName
                if let poiCategory = locationEditModel.locationPOI?.poiCategory {
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
                    print("Save try complete")
                    globalVars.locationUpdated.toggle()
                    print("globalVars toggled")
                    dismiss()
                } catch {
                    print("error saving location: \(error)")
                }
                globalVars.showLocationSetUpView = false
            }
        }
        //                            if let image = location.poiImage {
        //                                VStack {
        //                                    image
        //                                        .resizable()
        //                                        .aspectRatio(contentMode: .fit)
        //                                        .frame(width: 200, height: 200)
        //                                        .background(location.poiColor ?? .white)
        //                                        .clipShape(RoundedRectangle(cornerRadius: 10)) // Rounded rectangle with 10-point corners
        //                                        .shadow(radius: 5) // Optional: adds a subtle shadow
        //
        //                                    Text("color: \(String(describing: location.poiColor))")
        //                                    Text("category: \(String(describing: location.poiCategory))")
        //                                }
        //                            }
 

        .onAppear() {
            print("view appeared")
            if locationEditModel.startLocation {
                locationType = LocationType.startLocation
            }
            globalVars.selectedDetent = .fraction(0.5)
            if globalVars.locationIndex != -99 {
                locationIndex = globalVars.locationIndex
            } else {
                locationIndex = Int(locationEditModel.locationIndex)
            }
            dayIndex = globalVars.selectedTabIndex - 1
            if let trip = globalVars.selectedTrip {
                viewModel.getDates(trip: trip, dayIndex: dayIndex)
            }
            leaveDate = viewModel.dayFromDayIndex + TimeInterval(numberOfNights * 60 * 60 * 24)
            if globalVars.locationType == .startLocation {
                startLocation = true
            }
        }
        .onChange(of: locationEditModel.name) {
            localName = locationEditModel.name
        }
        .onChange (of: selectedPOI) {
            locationEditModel.locationPOI = selectedPOI
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
