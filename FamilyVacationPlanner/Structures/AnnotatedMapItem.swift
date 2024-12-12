//
//  AnnotatedMapItem.swift
//  FamilyVacationPlanner
//
//  Created by David Steele on 6/28/24.
//

import MapKit
import Foundation

struct AnnotatedMapItem: Identifiable, Hashable {
    let id: String // Unique identifier for the item
    var item: MKMapItem

    init(item: MKMapItem) {
        self.id = UUID().uuidString // Generate unique ID using UUID
        self.item = item
  }
}
