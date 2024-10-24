//
//  EditTripView.swift
//  FamilyVacationPlanner
//
//  Created by David Steele on 6/27/24.
//

import CoreData
import SwiftUI

struct EditTripView: View {
    @Binding var editMode: Bool
    @Binding var newTrip: Bool
    @Binding var path: NavigationPath

    
    @Environment(DataModel.self) private var dataModel
    @FocusState private var isTextFieldFocused: Bool
    @State var trip: Trip
    @State private var endDate: Date = Date()
    @State private var startDate: Date = Date()
    @State private var tripName: String = ""
    @State private var oneWayToggle: Bool = false
    
    var body: some View {
        VStack {
            VStack {
                Form {
                    Section("Trip Info") {
                        TextField("Trip Name", text: $tripName)
                            //.autocorrectionDisabled()
                            .focused($isTextFieldFocused)
                        DatePicker("Trip Start", selection: $startDate, displayedComponents: [.date])
                        DatePicker("Trip Finish", selection: $endDate, displayedComponents: [.date])
                        Toggle("One Way", isOn: $oneWayToggle)
                            .toggleStyle(.switch)
                        Button(action: {
                            trip.tripName = tripName
                            trip.startDate = startDate
                            trip.endDate = endDate
                            trip.oneWay = oneWayToggle
                            try? dataModel.moc.save()
                            editMode = false
                            newTrip = false
                            //path.append(trip)
                        }, label: {
                            Text("Save Trip")
                        })
                    }
                }
            }
            .onAppear() {
                tripName = trip.tripName ?? ""
                startDate = trip.startDate ?? Date()
                endDate = trip.endDate ?? Date()
                oneWayToggle = trip.oneWay
                isTextFieldFocused = true
                print("text field appeared")
            }
            .onDisappear{
                if newTrip {
                    dataModel.moc.delete(trip)
                }
            }
            .onChange(of: startDate) {
                isTextFieldFocused = false
                print("start date changed")
            }
            .onChange(of: endDate) {
                isTextFieldFocused = false
                print("end date changed")
            }
            .onChange(of: oneWayToggle) {
                isTextFieldFocused = false
                print("toggle changed")
            }
        }
    }
}

