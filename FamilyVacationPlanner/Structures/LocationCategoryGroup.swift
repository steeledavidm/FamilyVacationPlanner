//
//  LocationCategoryGroup.swift
//  FamilyVacationPlanner
//
//  Created by David Steele on 11/20/24.
//

import Foundation
import MapKit

enum CategoryGroup: String, CaseIterable {
    case lodging = "Lodging"
    case cultureAndEntertainment = "Culture & Entertainment"
    case natureAndParks = "Nature & Parks"
    case sportsAndRecreation = "Sports & Recreation"
    case transportation = "Transportation"
    case shoppingAndServices = "Shopping & Services"
    case educationAndInstitutions = "Education"
    case emergencyServices = "Emergency Services"
    case attractions = "Attractions"
    case postAndMail = "Post & Mail"
    case other = "Other"
}

enum POICategories: Hashable {
    // Lodging
    case hotel, campground
    
    // Culture and Entertainment
    case museum, theater, movieTheater, library, nightlife
    
    // Nature and Parks
    case park, nationalPark, beach, marina
    
    // Sports and Recreation
    case fitnessCenter
    
    // Transportation
    case airport, parking, publicTransport, carRental, evCharger
    
    // Shopping and Services
    case restaurant, cafe, bakery, brewery, winery, foodMarket,
         store, bank, atm, gasStation, pharmacy, laundry
    
    // Education and Institutions
    case school, university
    
    // Emergency Services
    case hospital, police, fireStation
    
    // Attractions
    case aquarium, zoo
    
    // Post and Mail
    case postOffice
    
    // Other
    case restroom, stadium
    
    var mkCategory: MKPointOfInterestCategory {
        switch self {
        // Lodging
        case .hotel: return .hotel
        case .campground: return .campground
        
        // Culture and Entertainment
        case .museum: return .museum
        case .theater: return .theater
        case .movieTheater: return .movieTheater
        case .library: return .library
        case .nightlife: return .nightlife
        
        // Nature and Parks
        case .park: return .park
        case .nationalPark: return .nationalPark
        case .beach: return .beach
        case .marina: return .marina
        
        // Sports and Recreation
        case .fitnessCenter: return .fitnessCenter
        
        // Transportation
        case .airport: return .airport
        case .parking: return .parking
        case .publicTransport: return .publicTransport
        case .carRental: return .carRental
        case .evCharger: return .evCharger
        
        // Shopping and Services
        case .restaurant: return .restaurant
        case .cafe: return .cafe
        case .bakery: return .bakery
        case .brewery: return .brewery
        case .winery: return .winery
        case .foodMarket: return .foodMarket
        case .store: return .store
        case .bank: return .bank
        case .atm: return .atm
        case .gasStation: return .gasStation
        case .pharmacy: return .pharmacy
        case .laundry: return .laundry
        
        // Education and Institutions
        case .school: return .school
        case .university: return .university
        
        // Emergency Services
        case .hospital: return .hospital
        case .police: return .police
        case .fireStation: return .fireStation
        
        // Attractions
        case .aquarium: return .aquarium
        case .zoo: return .zoo
        
        // Post and Mail
        case .postOffice: return .postOffice
        
        // Other
        case .restroom: return .restroom
        case .stadium: return .stadium
        }
    }
}

struct LocationCategoryGroup: Hashable {
    let selectedGroup: CategoryGroup
    var poiCategories: [POICategories] {
        
        switch selectedGroup {
        case .lodging:
            return [.hotel, .campground]
        case .cultureAndEntertainment:
            return [.museum, .theater, .movieTheater, .library, .nightlife]
        case .natureAndParks:
            return [.park, .nationalPark, .beach, .marina]
        case .sportsAndRecreation:
            return [.fitnessCenter]
        case .transportation:
            return [.airport, .parking, .publicTransport, .carRental, .evCharger]
        case .shoppingAndServices:
            return [.restaurant, .cafe, .bakery, .brewery, .winery, .foodMarket,
                    .store, .bank, .atm, .gasStation, .pharmacy, .laundry]
        case .educationAndInstitutions:
            return [.school, .university]
        case .emergencyServices:
            return [.hospital, .police, .fireStation]
        case .attractions:
            return [.aquarium, .zoo]
        case .postAndMail:
            return [.postOffice]
        case .other:
            return [.restroom, .stadium]
        }
    }
}


