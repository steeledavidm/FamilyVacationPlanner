//
//  LocationSetUp.swift
//  FamilyVacationPlanner
//
//  Created by David Steele on 12/11/24.
//

import Foundation
import MapKit
import SwiftUI

struct LocationSetUp: Identifiable {
    let id: UUID
    let name: String
    let title: String?
    let subtitle: String?
    let latitude: Double
    let longitude: Double
    let poiCategory: MKPointOfInterestCategory?
    let poiImage: Image?
    let poiColor: Color?
    
    init(from annotatedMapItem: AnnotatedMapItem) {
        self.id = UUID()
        self.name = annotatedMapItem.item.name ?? ""
        self.title = annotatedMapItem.item.placemark.title ?? ""
        self.subtitle = annotatedMapItem.item.placemark.subtitle
        self.latitude = annotatedMapItem.item.placemark.coordinate.latitude
        self.longitude = annotatedMapItem.item.placemark.coordinate.longitude
        self.poiCategory = annotatedMapItem.item.pointOfInterestCategory
        self.poiImage = nil
        self.poiColor = nil
    }
    
    init(from mapFeature: MapFeature, title: String, subtitle: String) {
        self.id = UUID()
        self.name = mapFeature.title ?? ""
        self.title = title
        self.subtitle = subtitle
        self.latitude = mapFeature.coordinate.latitude
        self.longitude = mapFeature.coordinate.longitude
        self.poiCategory = mapFeature.pointOfInterestCategory
        self.poiImage = mapFeature.image
        self.poiColor = mapFeature.backgroundColor
    }
}
