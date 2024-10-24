//
//  DestinationSetUpView.swift
//  FamilyVacationPlanner
//
//  Created by David Steele on 6/29/24.
//

//import CoreData
//import SwiftUI
//
//struct DestinationSetUpView: View {
//    @Binding var annotationItem: AnnotationItem
//    @State private var trip: Trip = Trip()
//    @Environment(DataModel.self) private var dataModel
//    //@Environment(\.managedObjectContext) var moc
//    @Environment(GlobalVariables.self) private var globalVars
//    @FocusState private var isFocusedTextFieldDestination: Bool
//    @State private var overNightStop: Bool = false
//    @State private var dateArrive: Date = .now
//    @State private var dateLeave: Date = .now
//    @State private var requester: String = "Requester"
//    @State private var status: String = "Review"
//    @State private var startLocation: Bool = false
//    @State private var goToTripOverview: Bool = false
//    @State private var addLocationType: String = "Not Set"
//    @State private var notes: String = ""
//    @State private var selectedStartLocation: Location = Location()
//    @State private var possibleStartLocationsIndex: Int = 0
//    @State private var possibleStartLocations: [Location] = []
//    @State private var locationType: LocationType = .startLocation
//    
//
//    var body: some View {
//        VStack {
//            Form {
//                Section(header: Text("Name")
//                    .font(.headline)
//                    .foregroundColor(.black)
//                    .padding(EdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 0))
//                ) {
//                    TextField("Name", text: $annotationItem.name)
//                        .overlay {
//                            ClearButton(text: $annotationItem.name)
//                                .padding(.top, 2)
//                        }
//                        .focused($isFocusedTextFieldDestination)
//                }
//                .textCase(nil)
//                
//                Section(header: Text("Address")
//                    .font(.headline)
//                    .foregroundColor(.black)
//                    .padding(EdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 0))
//                ) {
//                    TextField("Address", text: $annotationItem.title)
//                }
//                .textCase(nil)
//                
//                VStack {
//                    if case .startLocation = locationType {
//                        DatePicker("Depart", selection: $dateLeave)
//                        if !(trip.oneWay) {
//                            DatePicker("Return", selection: $dateArrive)
//                        }
//                        
//                    }
//                    
//                    if case .endLocation = locationType {
//                        
//                    }
//                    
//                    if case .overNightStop = locationType {
//                        DatePicker("Arrive", selection: $dateArrive)
//                        DatePicker("Depart", selection: $dateLeave)
//                    }
//                    if case .pointOfInterest = locationType {
//                        Picker("Select Start Location", selection: $possibleStartLocationsIndex) {
//                            ForEach(possibleStartLocations.indices) { index in
//                                Text(possibleStartLocations[index].name ?? "")
//                            }
//                        }
//                        //DatePicker("Arrive", selection: $dateArrive)
//                       //DatePicker("Depart", selection: $dateLeave)
//                    }
//                }
//                Section(header: Text("Notes")
//                    .font(.headline)
//                    .foregroundColor(.black)
//                    .padding(EdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 0))
//                ) {
//                    TextField("Notes", text: $notes)
//                }
//                .textCase(nil)
//            }
//            
//            .onAppear {
//                trip = globalVars.trip ?? Trip()
//                locationType = globalVars.locationType ?? .startLocation
//                isFocusedTextFieldDestination = true
//                switch locationType {
//                case .startLocation:
//                    addLocationType = "Set Start Location"
//                    startLocation = true
//                    dateLeave = trip.startDate ?? Date()
//                    dateArrive = trip.endDate ?? Date()
//                case .endLocation:
//                    addLocationType = "Set End Location"
//                case .overNightStop:
//                    addLocationType = "Add Overnight Stop"
//                    overNightStop = true
//                    dateArrive = trip.startDate ?? Date() + 1
//                    dateLeave = dateArrive + 60*60*24
//                case .pointOfInterest:
//                    addLocationType = "Add Point Of Interest"
//     
////                    dateArrive = daySegments.first?.dayDate ?? Date()//adding 1 second so leave time is after trip start time
////                    dateLeave = daySegments.first?.dayDate  ?? Date() //adding 1 second so leave time is after trip start time
////                    print("DateArrive and DateLeave \(dateArrive), \(dateLeave)")
////                    for daySegment in daySegments {
////                        possibleStartLocations.append(daySegment.startLocation)
////                    }
//                case .currentLocation:
//                    print("Current Location Type")
//                }
//            }
//            
//            Button(action: {
//                let location = Location(context: dataModel.moc)
//                location.id = UUID()
//                location.name = annotationItem.name
//                location.title = annotationItem.title
//                location.subtitle = annotationItem.subtitle
//                location.latitude = annotationItem.latitude
//                location.longitude = annotationItem.longitude
//                location.dateArrive = dateArrive
//                location.dateLeave = dateLeave
//                location.requester = requester
//                location.status = status
//                location.startLocation = startLocation
//                location.overNightStop = overNightStop
//                location.startIndex = Int16(possibleStartLocationsIndex)
//                trip.addToLocation(location)
//                try? dataModel.moc.save()
//                if locationType == LocationType.pointOfInterest {
//                    selectedStartLocation = possibleStartLocations[possibleStartLocationsIndex]
//                }
//                //isPresented.toggle()
//            }, label: {
//                Text(addLocationType)
//                    .padding()
//                    .background(Color(.blue))
//                    .foregroundColor(.white)
//                    .clipShape(.capsule)
//            })
//        
//            Spacer()
//        }
//    }
//}
//
///*
//#Preview {
//    let context = DataController.preview
//    let trips: [Trip]
//    let requestTrips: NSFetchRequest<Trip> = Trip.fetchRequest()
//    do {
//        trips = try context.fetch(requestTrips)
//    } catch {
//        let nserror = error as NSError
//        fatalError("Error \(nserror): \(nserror.userInfo)")
//    }
//    let isPresented = false
//    let trip = trips[1]
//    let locationType: LocationType = .startLocation
//    let locationsForDay = [Segment(dayDate: Date(), dayString: "Today", startLocation: Location(), endLocation: Location())]
//    let daySegments = [Segment(dayDate: Date(), dayString: "", startLocation: Location(), endLocation: Location())]
//
//    return DestinationSetUpView(annotationItem: .constant(AnnotationItem(name: "My House", title: "201 Whitetail Ridge, Hudson, IA  50643, United States", subtitle: "", latitude: 42.0, longitude: -92.0)), trip: .constant(trip), isPresented: .constant(isPresented), locationType: locationType, daySegments: $daySegments)
//        
//}
// */
//
