//
//  CustomMapMarkertView.swift
//  FamilyVacationPlanner
//
//  Created by David Steele on 11/18/24.
//

import MapKit
import SwiftUI

@available(iOS 18.0, *)
struct CustomMapMarkerView: View {

    let category: MKPointOfInterestCategory?
    let title: String
    
    var body: some View {
        markerContent
            .foregroundStyle(markerColor)
    }
    
    private var markerContent: some View {
        switch category {
        // Lodging
        case .hotel, .campground, .rvPark:
            return AnyView(Image(systemName: "bed.double.fill")
                .font(.system(size: 24)))
            
        // Food and Drink
        case .restaurant, .bakery:
            return AnyView(Image(systemName: "fork.knife")
                .font(.system(size: 24)))
        case .cafe:
            return AnyView(Image(systemName: "cup.and.saucer.fill")
                .font(.system(size: 24)))
        case .brewery, .winery, .distillery:
            return AnyView(Image(systemName: "wineglass.fill")
                .font(.system(size: 24)))
        case .foodMarket:
            return AnyView(Image(systemName: "cart.fill")
                .font(.system(size: 24)))
            
        // Culture and Entertainment
        case .museum, .theater, .movieTheater, .musicVenue:
            return AnyView(Image(systemName: "building.columns.fill")
                .font(.system(size: 24)))
        case .library:
            return AnyView(Image(systemName: "books.vertical.fill")
                .font(.system(size: 24)))
        case .nightlife:
            return AnyView(Image(systemName: "moon.stars.fill")
                .font(.system(size: 24)))
            
        // Nature and Parks
        case .park, .nationalPark, .nationalMonument:
            return AnyView(Image(systemName: "leaf.fill")
                .font(.system(size: 24)))
        case .beach:
            return AnyView(Image(systemName: "umbrella.fill")
                .font(.system(size: 24)))
        case .marina:
            return AnyView(Image(systemName: "boat.fill")
                .font(.system(size: 24)))
            
        // Sports and Recreation
        case .fitnessCenter, .spa:
            return AnyView(Image(systemName: "figure.run")
                .font(.system(size: 24)))
        case .baseball, .basketball, .soccer, .volleyball, .tennis:
            return AnyView(Image(systemName: "sportscourt.fill")
                .font(.system(size: 24)))
        case .bowling:
            return AnyView(Image(systemName: "circle.circle.fill")
                .font(.system(size: 24)))
        case .golf, .miniGolf:
            return AnyView(Image(systemName: "flag.fill")
                .font(.system(size: 24)))
        case .skating, .skatePark:
            return AnyView(Image(systemName: "figure.skating")
                .font(.system(size: 24)))
        case .skiing:
            return AnyView(Image(systemName: "snow")
                .font(.system(size: 24)))
        case .swimming, .surfing, .kayaking:
            return AnyView(Image(systemName: "water.waves")
                .font(.system(size: 24)))
        case .rockClimbing, .hiking:
            return AnyView(Image(systemName: "mountain.2.fill")
                .font(.system(size: 24)))
            
        // Transportation
        case .airport:
            return AnyView(Image(systemName: "airplane")
                .font(.system(size: 24)))
        case .parking:
            return AnyView(Image(systemName: "p.circle.fill")
                .font(.system(size: 24)))
        case .publicTransport:
            return AnyView(Image(systemName: "bus.fill")
                .font(.system(size: 24)))
        case .carRental:
            return AnyView(Image(systemName: "car.fill")
                .font(.system(size: 24)))
        case .evCharger:
            return AnyView(Image(systemName: "bolt.car.fill")
                .font(.system(size: 24)))
            
        // Shopping and Services
        case .store:
            return AnyView(Image(systemName: "bag.fill")
                .font(.system(size: 24)))
        case .bank, .atm:
            return AnyView(Image(systemName: "dollarsign.circle.fill")
                .font(.system(size: 24)))
        case .gasStation:
            return AnyView(Image(systemName: "fuelpump.fill")
                .font(.system(size: 24)))
        case .pharmacy:
            return AnyView(Image(systemName: "cross.case.fill")
                .font(.system(size: 24)))
        case .laundry:
            return AnyView(Image(systemName: "washer.fill")
                .font(.system(size: 24)))
        case .beauty:
            return AnyView(Image(systemName: "scissors")
                .font(.system(size: 24)))
        case .animalService:
            return AnyView(Image(systemName: "pawprint.fill")
                .font(.system(size: 24)))
            
        // Education and Institutions
        case .school, .university:
            return AnyView(Image(systemName: "graduationcap.fill")
                .font(.system(size: 24)))
            
        // Emergency Services
        case .hospital:
            return AnyView(Image(systemName: "cross.fill")
                .font(.system(size: 24)))
        case .police:
            return AnyView(Image(systemName: "shield.fill")
                .font(.system(size: 24)))
        case .fireStation:
            return AnyView(Image(systemName: "flame.fill")
                .font(.system(size: 24)))
            
        // Attractions
        case .amusementPark, .fairground:
            return AnyView(Image(systemName: "ferriswheel")
                .font(.system(size: 24)))
        case .aquarium:
            return AnyView(Image(systemName: "fish.fill")
                .font(.system(size: 24)))
        case .zoo:
            return AnyView(Image(systemName: "hare.fill")
                .font(.system(size: 24)))
        case .castle, .fortress, .landmark:
            return AnyView(Image(systemName: "building.columns.circle.fill")
                .font(.system(size: 24)))
        case .planetarium:
            return AnyView(Image(systemName: "star.fill")
                .font(.system(size: 24)))
            
        // Post and Mail
        case .postOffice:
            return AnyView(Image(systemName: "envelope.fill")
                .font(.system(size: 24)))
        case .mailbox:
            return AnyView(Image(systemName: "mail.stack.fill")
                .font(.system(size: 24)))
            
        // Other
        case .restroom:
            return AnyView(Image(systemName: "figure.dress.line.vertical.figure")
                .font(.system(size: 24)))
        case .stadium, .conventionCenter:
            return AnyView(Image(systemName: "building.2.fill")
                .font(.system(size: 24)))
            
        default:
            return AnyView(Image(systemName: "mappin.circle.fill")
                .font(.system(size: 24)))
        }
    }
    
    private var markerColor: Color {
        switch category {
        // Lodging
        case .hotel, .campground, .rvPark:
            return .blue
            
        // Food and Drink
        case .restaurant, .cafe, .brewery, .winery, .distillery, .bakery, .foodMarket:
            return .orange
            
        // Culture and Entertainment
        case .museum, .theater, .movieTheater, .library, .nightlife, .musicVenue:
            return .purple
            
        // Nature and Parks
        case .park, .nationalPark, .beach, .marina, .nationalMonument:
            return .green
            
        // Sports and Recreation
        case .fitnessCenter, .baseball, .basketball, .soccer, .volleyball,
             .tennis, .bowling, .golf, .miniGolf, .skating, .skatePark,
             .skiing, .swimming, .surfing, .kayaking, .rockClimbing, .hiking, .spa:
            return .mint
            
        // Transportation
        case .airport, .parking, .publicTransport, .carRental, .evCharger:
            return .indigo
            
        // Shopping and Services
        case .store, .bank, .atm, .pharmacy, .laundry, .beauty, .animalService:
            return .pink
            
        // Education and Institutions
        case .school, .university:
            return .brown
            
        // Emergency Services
        case .hospital, .police, .fireStation:
            return .red
            
        // Attractions
        case .amusementPark, .aquarium, .zoo, .castle, .fortress,
             .landmark, .planetarium, .fairground:
            return .yellow
            
        // Post and Mail
        case .postOffice, .mailbox:
            return .gray
            
        default:
            return .secondary
        }
    }
}

#Preview {
    if #available(iOS 18.0, *) {
        CustomMapMarkerView(category: .restaurant, title: "marker Name")
    } else {
        // Fallback on earlier versions
    }
}
