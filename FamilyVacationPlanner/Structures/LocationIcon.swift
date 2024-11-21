//
//  LocationIcon.swift
//  FamilyVacationPlanner
//
//  Created by David Steele on 11/19/24.
//

// 1. MKMapItem.MKPointOfInterestCategory from selected item on Map.
// 2. LocationSetUpView
//  a. Shows current poiCategory,icon and color from selected item
//  b. Option to change the poiCategory from list of possibilities
//  c. Save to Location.categoryRawValue
// 3. ContentView
//  a. Converts Location.categoryRawValue to icon,color.
//  b. Loads MapInfo and displays on Map.
// 4. DaySegmentsView
//  a. 

import Foundation
import MapKit
import SwiftUI

struct LocationIcon: Identifiable, Hashable {
    let id: UUID = UUID()
    let poiCategory: MKPointOfInterestCategory?
    
    var poiSymbol: String? {
        
        switch poiCategory {
            // Lodging
        case .hotel:
            return "bed.double.fill"
        case .campground:
            return "tent.fill"
        case .restaurant:
            return "fork.knife"
        case .bakery:
            return "birthday.cake.fill"
        case .cafe:
            return "cup.and.saucer.fill"
        case .brewery, .winery:
            return "wineglass.fill"
        case .foodMarket:
            return "cart.fill"
            
            // Culture and Entertainment
        case .museum:
            return "building.columns.fill"
        case .theater:
            return "theatermasks.fill"
        case .movieTheater:
            return "movieclapper.fill"
        case .library:
            return "books.vertical.fill"
        case .nightlife:
            return "moon.stars.fill"
            
            // Nature and Parks
        case .park:
            return "tree.fill"
        case .nationalPark:
            return "mountain.2.fill"
        case .beach:
            return "umbrella.fill"
        case .marina:
            return "sailboat.fill"
            
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
    // Readable name for the category
    var poiDisplayName: String {
        switch poiCategory {
        // Lodging
        case .hotel: return "Hotel"
        case .campground: return "Campground"
        
        // Culture and Entertainment
        case .museum: return "Museum"
        case .theater: return "Theater"
        case .movieTheater: return "Movie Theater"
        case .library: return "Library"
        case .nightlife: return "Nightlife"
        
        // Nature and Parks
        case .park: return "Park"
        case .nationalPark: return "National Park"
        case .beach: return "Beach"
        case .marina: return "Marina"
        
        // Sports and Recreation
        case .fitnessCenter: return "Fitness Center"
        
        // Transportation
        case .airport: return "Airport"
        case .parking: return "Parking"
        case .publicTransport: return "Public Transport"
        case .carRental: return "Car Rental"
        case .evCharger: return "EV Charger"
        
        // Shopping and Services
        case .restaurant: return "Restaurant"
        case .cafe: return "Cafe"
        case .bakery: return "Bakery"
        case .brewery: return "Brewery"
        case .winery: return "Winery"
        case .foodMarket: return "Food Market"
        case .store: return "Store"
        case .bank: return "Bank"
        case .atm: return "ATM"
        case .gasStation: return "Gas Station"
        case .pharmacy: return "Pharmacy"
        case .laundry: return "Laundry"
        
        // Education and Institutions
        case .school: return "School"
        case .university: return "University"
        
        // Emergency Services
        case .hospital: return "Hospital"
        case .police: return "Police"
        case .fireStation: return "Fire Station"
        
        // Attractions
        case .aquarium: return "Aquarium"
        case .zoo: return "Zoo"
        
        // Post and Mail
        case .postOffice: return "Post Office"
        
        // Other
        case .restroom: return "Restroom"
        case .stadium: return "Stadium"
        case .none: return ""
        case .some(_): return ""
        }
    }
}

