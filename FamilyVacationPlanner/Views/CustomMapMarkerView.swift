//
//  CustomMapMarkertView.swift
//  FamilyVacationPlanner
//
//  Created by David Steele on 11/18/24.
//

import MapKit
import SwiftUI


struct CustomMapMarkerView: View {

    let poiSymbol: String
    let poiColor: Color
    let title: String
    
    var body: some View {
        markerContent
            .foregroundStyle(poiColor)
    }
    
    var markerContent: some View {
        return AnyView(Image(systemName: poiSymbol)
                .font(.system(size: 24)))
    }
}

#Preview {
    let poiSymbol = "house"
    CustomMapMarkerView(poiSymbol: poiSymbol, poiColor: .red, title: "marker Name")
}

