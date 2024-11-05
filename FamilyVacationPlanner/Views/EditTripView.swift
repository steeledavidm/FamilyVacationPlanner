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
    @State var trip: Trip
    @State private var endDate: Date = Date()
    @State private var startDate: Date = Date()
    @State private var tripName: String = ""
    @State private var oneWayToggle: Bool = false
    @State private var showingStartDatePicker = false
    @State private var showingEndDatePicker = false
    
    var body: some View {
        VStack {
            VStack {
                Form {
                    Section("Trip Info") {
                        TextField("Trip Name", text: $tripName)
                            .autocorrectionDisabled()
                            .submitLabel(.return)
                         Button(action: { showingStartDatePicker = true }) {
                             HStack {
                                 Text("Trip Start")
                                 Spacer()
                                 Text(startDate.formatted(date: .numeric, time: .omitted))
                             }
                         }
                         .sheet(isPresented: $showingStartDatePicker) {
                             NavigationStack {
                                 DatePicker("Select Start Date",
                                          selection: $startDate,
                                          displayedComponents: [.date])
                                     .datePickerStyle(.graphical)
                                     .padding()
                                     .navigationTitle("Select Start Date")
                                     .navigationBarTitleDisplayMode(.inline)
                                     .toolbar {
                                         ToolbarItem(placement: .confirmationAction) {
                                             Button("Done") {
                                                 showingStartDatePicker = false
                                             }
                                         }
                                     }
                             }
                             .presentationDetents([.medium])
                         }
                         .onChange(of: startDate) {
                             showingStartDatePicker = false
                         }
                         
                         Button(action: { showingEndDatePicker = true }) {
                             HStack {
                                 Text("Trip Finish")
                                 Spacer()
                                 Text(endDate.formatted(date: .numeric, time: .omitted))
                             }
                         }
                         .sheet(isPresented: $showingEndDatePicker) {
                             NavigationStack {
                                 DatePicker("Select End Date",
                                          selection: $endDate,
                                          displayedComponents: [.date])
                                     .datePickerStyle(.graphical)
                                     .padding()
                                     .navigationTitle("Select End Date")
                                     .navigationBarTitleDisplayMode(.inline)
                                     .toolbar {
                                         ToolbarItem(placement: .confirmationAction) {
                                             Button("Done") {
                                                 showingEndDatePicker = false
                                             }
                                         }
                                     }
                             }
                             .presentationDetents([.medium])
                         }
                         .onChange(of: endDate) {
                             showingEndDatePicker = false
                         }
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
                print("text field appeared")
            }
            .onDisappear{
                if newTrip {
                    dataModel.moc.delete(trip)
                }
            }
        }
    }
}

