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
    let locationFromMap: AnnotatedMapItem
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
    
    var body: some View {
        Form {
            Section("Location Name"){
                TextField("Location name", text: $locationName )
            }
            Section("Address"){
                Text(address)
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
            
            Section("Date Arrive") {
                Text("\(viewModel.dayFromDayIndex)")
            }
            Section("Date Leave") {
                DatePicker("Date Leave", selection: $leaveDate, displayedComponents: [.date])
            }
            Button("Save") {
                let location = Location(context: dataModel.moc)
                guard let trip = globalVars.selectedTrip else { return }
                location.id = UUID()
                location.name = locationName
                location.title = address
                location.latitude = locationFromMap.item.placemark.coordinate.latitude
                location.longitude = locationFromMap.item.placemark.coordinate.longitude
                if locationType == LocationType.startLocation {
                    location.startLocation = true
                    location.dateLeave = trip.startDate
                    if !trip.oneWay {
                        location.dateArrive = trip.endDate
                    }
                }
                if overnightStop {
                    locationType = LocationType.overNightStop
                }
                if locationType == LocationType.overNightStop {
                    location.overNightStop = true
                    location.dateArrive = viewModel.dayFromDayIndex
                    location.numberOfNights = Int16(numberOfNights)
                    location.dateLeave = leaveDate
                }
                if locationType == LocationType.pointOfInterest {
                    location.dateArrive = viewModel.dayFromDayIndex
                    location.dateLeave = viewModel.dayFromDayIndex
                }
                trip.addToLocation(location)
                viewModel.getLocationIndex(location: location, dayIndex: dayIndex, locationIndex: locationIndex)
                globalVars.locationAdded.toggle()
                globalVars.showSearchLocationSheet = false
                dismiss()
            }
        }

        .onAppear() {
            print("view appeared")
            globalVars.selectedDetent = .fraction(0.5)
            locationName = locationFromMap.item.name ?? ""
            placemark = locationFromMap.item.placemark
            address = placemark.title ?? ""
            locationType = globalVars.locationType ?? LocationType.pointOfInterest
            locationIndex = globalVars.locationIndex
            dayIndex = globalVars.selectedTabIndex
            if let trip = globalVars.selectedTrip {
                viewModel.getDates(trip: trip, dayIndex: dayIndex)
            }
            leaveDate = viewModel.dayFromDayIndex + TimeInterval(numberOfNights * 60 * 60 * 24)
        }
    }
}

#Preview {
    let locationFromMap = AnnotatedMapItem(item: MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: 42, longitude: -92))))
    LocationSetUpView(locationFromMap: locationFromMap)
        .environment(DataModel())
        .environment(GlobalVariables())
    
}
