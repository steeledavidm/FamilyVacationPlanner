//
//  SectionHeaderView.swift
//  FamilyVacationPlanner
//
//  Created by David Steele on 6/28/24.
//

import SwiftUI

struct SectionHeaderView: View {
    let date: Date
    @State private var headerText: String = ""
    @Binding var isPresented: Bool
    @Binding var locationType: LocationType
    @Binding var comprehensive: Bool
    
    var body: some View {
        if !comprehensive {
            HStack {
                Text(formatDate(date: date))
                    .padding()
                Spacer()
                Button(action: {isPresented = true
                }, label: {
                    Text(headerText)
                })
                .padding()
            }
            .onAppear {
                switch locationType {
                case .startLocation:
                    headerText = ""
                case .endLocation:
                    headerText = ""
                case .overNightStop:
                    headerText = "Add Overnight Stop"
                case .pointOfInterest:
                    headerText = "Add Point of Interest"
                }
            }
        } else {
            Text("Complete Trip, Swipe for details")
        }
    }
}

#Preview {
    SectionHeaderView(date: Date(), isPresented: .constant(false), locationType: .constant(.overNightStop), comprehensive: .constant(false))
}

func formatDate(date: Date) -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "EEEE, MMMM dd"
    
    let formattedDate = dateFormatter.string(from: date)
    return formattedDate
    
}


