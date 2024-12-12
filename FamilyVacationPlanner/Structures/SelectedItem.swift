//
//  SelectedItem.swift
//  FamilyVacationPlanner
//
//  Created by David Steele on 12/10/24.
//

import Foundation

struct SelectedItem: Identifiable {
    let id = UUID()
    let itemType: SelectedItemType
}
