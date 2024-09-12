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
    @State var locationFromMap: AnnotatedMapItem
    
    var body: some View {
//        Text(locationForView.name ?? "")
//        Text(locationForView.title ?? "")
//        Text(locationForView.subtitle ?? "")
//        Text(String(locationForView.latitude))
//        Text(String(locationForView.longitude))
        Text("hello")

            .onAppear() {
                let location = Location(context: dataModel.moc)
                let placemark = locationFromMap.item.placemark
                location.name = locationFromMap.item.name
                location.title = "\(String(describing: placemark.title)), \(String(describing: placemark.locality)), \(String(describing: placemark.administrativeArea)), \(String(describing: placemark.postalCode)), \(String(describing: placemark.country))"
                location.subtitle = placemark.subtitle
                location.latitude = placemark.coordinate.latitude
                location.longitude = placemark.coordinate.longitude
                
                print(location.name ?? "")
                print(location.title ?? "")
                print(location.subtitle ?? "")
                print(location.latitude)
                print(location.longitude)
            }
    }
}

//#Preview {
//    LocationSetUpView()
//}
