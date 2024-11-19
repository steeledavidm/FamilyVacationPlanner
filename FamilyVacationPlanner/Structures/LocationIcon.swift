//
//  LocationIcon.swift
//  FamilyVacationPlanner
//
//  Created by David Steele on 11/19/24.
//

import Foundation
import MapKit
import SwiftUI

struct LocationIcon: Identifiable, Hashable {
    let id: UUID = UUID()
    let poiCategory: MKPointOfInterestCategory?
    
    var poiSymbol: String? {
        
        switch poiCategory {
            // Lodging
        case .hotel, .campground:
            return "bed.double.fill"
        case .restaurant, .bakery:
            return "fork.knife"
        case .cafe:
            return "cup.and.saucer.fill"
        case .brewery, .winery:
            return "wineglass.fill"
        case .foodMarket:
            return "cart.fill"
            
            // Culture and Entertainment
        case .museum, .theater, .movieTheater:
            return "building.columns.fill"
        case .library:
            return "books.vertical.fill"
        case .nightlife:
            return "moon.stars.fill"
            
            // Nature and Parks
        case .park, .nationalPark:
            return "leaf.fill"
        case .beach:
            return "umbrella.fill"
        case .marina:
            return "boat.fill"
            
            // Sports and Recreation
        case .fitnessCenter:
            return "figure.run"
            
            // Transportation
        case .airport:
            return "airplane"
        case .parking:
            return "p.circle.fill"
        case .publicTransport:
            return "bus.fill"
        case .carRental:
            return "car.fill"
        case .evCharger:
            return "bolt.car.fill"
            
            // Shopping and Services
        case .store:
            return "bag.fill"
        case .bank, .atm:
            return "dollarsign.circle.fill"
        case .gasStation:
            return "fuelpump.fill"
        case .pharmacy:
            return "cross.case.fill"
        case .laundry:
            return "washer.fill"
            
            // Education and Institutions
        case .school, .university:
            return "graduationcap.fill"
            
            // Emergency Services
        case .hospital:
            return "cross.fill"
        case .police:
            return "shield.fill"
        case .fireStation:
            return "flame.fill"
            
            // Attractions
        case .aquarium:
            return "fish.fill"
        case .zoo:
            return "hare.fill"
            
            // Post and Mail
        case .postOffice:
            return "envelope.fill"
            
            // Other
        case .restroom:
            return "figure.dress.line.vertical.figure"
        case .stadium:
            return "building.2.fill"
            
        default:
            return "mappin.circle.fill"
        }
    }
    var poiColor: Color {
        switch poiCategory {
        // Lodging
        case .hotel, .campground:
            return .blue
            
        // Food and Drink
        case .restaurant, .cafe, .brewery, .winery, .bakery, .foodMarket:
            return .orange
            
        // Culture and Entertainment
        case .museum, .theater, .movieTheater, .library, .nightlife:
            return .purple
            
        // Nature and Parks
        case .park, .nationalPark, .beach, .marina:
            return .green
            
        // Sports and Recreation
        case .fitnessCenter:
            return .mint
            
        // Transportation
        case .airport, .parking, .publicTransport, .carRental, .evCharger:
            return .indigo
            
        // Shopping and Services
        case .store, .bank, .atm, .pharmacy, .laundry:
            return .pink
            
        // Education and Institutions
        case .school, .university:
            return .brown
            
        // Emergency Services
        case .hospital, .police, .fireStation:
            return .red
            
        // Attractions
        case .amusementPark, .aquarium, .zoo:
            return .yellow
            
        // Post and Mail
        case .postOffice:
            return .gray
            
        default:
            return .secondary
        }
    }
}

