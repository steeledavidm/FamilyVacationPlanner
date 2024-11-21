//
//  POIPickerView.swift
//  FamilyVacationPlanner
//
//  Created by David Steele on 11/20/24.
//

import MapKit
import SwiftUI

struct POIPickerView: View {
    let group: CategoryGroup
    @Binding var selectedCategory: LocationIcon?
    @Binding var showPOISheet: Bool
    @Environment(\.dismiss) private var dismiss
    @State private var locationsIcons: [LocationIcon] = []
    
    var body: some View {
        List {
            ForEach(locationsIcons, id: \.self) {category in
                Button(action: {
                    selectedCategory = category
                    dismiss()
                    showPOISheet = false
                }) {
                    HStack {
                        Image(systemName: category.poiSymbol ?? "map.marker")
                            .foregroundColor(category.poiColor)
                            .frame(width: 30)
                        
                        Text(category.poiDisplayName)
                            .foregroundColor(.black)
                        
                        Spacer()
                    }
                }
            }
            .navigationTitle(group.rawValue)

        }
        .onAppear {
            let categoryGroup = LocationCategoryGroup(selectedGroup: group)
            let categories = categoryGroup.poiCategories
            for category in categories {
                locationsIcons.append(LocationIcon(poiCategory: category.mkCategory))
            }
        }
    }

}

#Preview {
    @Previewable @State var selectedCategory: LocationIcon? = LocationIcon(poiCategory: .postOffice)
    @Previewable @State var showPOISheet: Bool = false
    
    POIPickerView(
        group: .postAndMail,
        selectedCategory: $selectedCategory,
        showPOISheet: $showPOISheet
    )
}
