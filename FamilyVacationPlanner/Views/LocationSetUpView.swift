//
//  LocationSetUpView.swift
//  FamilyVacationPlanner
//
//  Created by David Steele on 9/6/24.
//

import MapKit
import SwiftUI

struct LocationSetUpView: View {
    @Environment(GlobalVariables.self) var globalVars
    @Environment(DataModel.self) var dataModel
    @Environment(\.dismiss) var dismiss
    let locationFromMap: AnnotatedMapItem
    @State private var placemark: MKPlacemark = MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0))
    @State private var locationName: String = ""
    @State private var address: String = ""
    @State private var notes: String = ""
    var body: some View {
        Form {
            Section("Location Name"){
                TextField("Location name", text: $locationName )
            }
            Section("Address"){
                Text(address)
            }
            Section("Notes") {
                TextField("Notes", text: $notes )
            }
            Button("Save") {
                let location = Location(context: dataModel.moc)
                location.id = UUID()
                location.name = locationName
                location.title = address
                //location.subtitle =
                location.latitude = locationFromMap.item.placemark.coordinate.latitude
                location.longitude = locationFromMap.item.placemark.coordinate.longitude
                //location.dateArrive = dateArrive
                //location.dateLeave = dateLeave
                //location.requester = requester
                //location.status = status
                if globalVars.locationType == LocationType.startLocation {
                    location.startLocation = true
                }
                if globalVars.locationType == LocationType.overNightStop {
                    location.overNightStop = true
                }
                //location.startIndex = Int16(possibleStartLocationsIndex)
                globalVars.trip?.addToLocation(location)
                try? dataModel.moc.save()
                dismiss()
            }
        }
//        Text(locationForView.name ?? "")
//        Text(locationForView.title ?? "")
//        Text(locationForView.subtitle ?? "")
//        Text(String(locationForView.latitude))
//        Text(String(locationForView.longitude))

        .onAppear() {
            print("view appeared")
            locationName = locationFromMap.item.name ?? ""
            placemark = locationFromMap.item.placemark
            address = placemark.title ?? ""
        }
    }
}

//#Preview {
//    LocationSetUpView()
//}
