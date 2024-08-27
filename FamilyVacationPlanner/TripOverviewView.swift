//
//  TripOverviewView.swift
//  FamilyVacationPlanner
//
//  Created by David Steele on 6/23/24.
//

import CoreData
import MapKit
import SwiftUI

struct TripOverviewView: View {
    @Environment(GlobalVariables.self) private var globalVar
    @Environment(LocationsViewModel.self) private var viewModel
    //@Environment(\.managedObjectContext) var moc
    @FetchRequest var locations: FetchedResults<Location>

    @State var trip: Trip
    @State private var allMapInfo: [MapInfo] = []
    //@State private var dateArray: [LocationsForDay] = []
    
    init(trip: Trip) {
        _locations = FetchRequest<Location>(sortDescriptors: [SortDescriptor(\.dateLeave)], predicate: NSPredicate(format: "%@ IN trip", trip))
        self.trip = trip
    }
    
   
    
    @State private var locationType: LocationType = .overNightStop
    @State private var isPresented = false
    @State private var position: MapCameraPosition = .automatic
    @State private var results: [MKMapItem] = []
    @State private var selectedResult: MKMapItem? = MKMapItem()
    @State private var region = MKCoordinateRegion()
    @State private var annotationItems: [AnnotationItem] = []
    @State private var markers: [Marker<Text>] = []
    @State private var mapRouteLines: [MapPolyline] = []
    @State private var startLocation: CLLocationCoordinate2D = CLLocationCoordinate2D()
    @State private var route: MKRoute?
    @State private var startingPoint: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 42.0, longitude: -92.0)
    @State private var endingPoint: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 42.0, longitude: -100.0)
    

    
    var body: some View {
        VStack {
            ZStack {
                Map(position: $position) {
                    ForEach(allMapInfo) {mapInfo in
                        Marker(mapInfo.markerLabelStart, coordinate: mapInfo.startingPoint ?? CLLocationCoordinate2D())
                    }
                }
                VStack() {
                    HStack {
                        Text(trip.tripName ?? "Unknown")
                            .font(.title)
                            .padding(.horizontal)
                            .background(Color(.blue))
                            .foregroundColor(.white)
                            .clipShape(.capsule)
                            .padding(.horizontal)
                            .shadow(radius: 5)
                        Spacer()
                    }
                    Text(trip.startDate!, style: .date)
                    Text(trip.endDate!, style: .date)
                    Spacer()
                }
            }
            Section(header: SectionHeaderView(date: trip.startDate ?? Date(), isPresented: $isPresented, locationType: $locationType, comprehensive: .constant(false))) {
                List {
                    ForEach(locations) {location in
                        NavigationLink(value: location) {
                            VStack(alignment: .leading) {
                                Text(location.name ?? "Unknown")
                                    .font(.headline)
                                Text(location.title ?? "Unknown")
                                    .font(.subheadline)
                                Text(location.dateArrive?.description ?? "Unknown")
                                Text(location.dateLeave?.description ?? "Unknown")
                                Text("Overnight Stay: \(location.overNightStop)")
                                Text("Start Location: \(location.startLocation)")
                            }
                        }
                    }
                    //.onDelete(perform: removeLocation)
                }
                .navigationTitle("Trip Overview")
                .navigationBarTitleDisplayMode(.inline)
            }
            VStack{
                NavigationLink(destination: DayLocationsView(trip: trip), label: {Text("Date Array")})
            }
            .padding()
        }
        .toolbar(.hidden, for: .navigationBar)
        
        .presentationDetents([.medium]) //.fraction(0.5), .medium])
        .interactiveDismissDisabled()
        .sheet(isPresented: $isPresented) {
            SearchDestinationView(trip: $trip, isPresented: $isPresented, locationType: $locationType, daySegments: .constant([Segment(dayDate: Date(), dayString: "", startLocation: Location(), endLocation: Location())]))
        }
        /*
        .onChange(of: globalVar.refreshMap) {
            print("running Get map info")
            getMapInfo()
            if locations.count == 1 {
                position = .region(MKCoordinateRegion(center: allMapInfo.first?.startingPoint ?? CLLocationCoordinate2D(), span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)))
                } else {
                    position = .automatic
                }
         
                
            
        }
    */
    }
    
    
    func getMapInfo() {
        let indexMax = locations.count - 1
        for location in locations {
            if location.startLocation {
                let locationCoordinates = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
                allMapInfo.append(MapInfo(locationid: location.id!, dateLeave: location.dateLeave!, markerLabelStart: location.name ?? "Marker", markerLabelEnd: location.name ?? "Marker", startingPoint: locationCoordinates, endingPoint: locationCoordinates))
                startLocation = locationCoordinates
            }
        }
        for (index, location) in locations.enumerated() {
            if !location.startLocation {
                let locationCoordinates = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
                allMapInfo.append(MapInfo(locationid: location.id!, dateLeave: location.dateLeave!, markerLabelStart: location.name ?? "Marker", markerLabelEnd: location.name ?? "Marker", startingPoint: locationCoordinates))
                let allMapInfoIndex = allMapInfo.count - 1
                allMapInfo[allMapInfoIndex - 1].endingPoint = locationCoordinates
                if !trip.oneWay && index == indexMax {
                    allMapInfo[allMapInfoIndex].endingPoint = startLocation
                }
            }
        }
        
        for (index, mapInfo) in allMapInfo.enumerated() {
            if !locations.contains(where: {$0.id == mapInfo.locationid}) {
                allMapInfo[index - 1].endingPoint = allMapInfo[index + 1].startingPoint
                allMapInfo.remove(at: index)
            }
        }
        
        print("trip.oneWay: \(trip.oneWay), indexMax: \(indexMax)")
        
        for (index, mapInfo) in allMapInfo.enumerated() {
            startingPoint = mapInfo.startingPoint ?? CLLocationCoordinate2D()
            endingPoint = mapInfo.endingPoint  ?? CLLocationCoordinate2D()
            
            print("startingPoint: \(startingPoint.latitude), endingPoint: \(endingPoint.latitude)")
            Task {
                do {
                    let route = try await getDirections()
                    allMapInfo[index].route = route
                } catch {
                    print("Error fetching data : \(error.localizedDescription)")
                }
            }
            allMapInfo.sort {$0.dateLeave < $1.dateLeave}
        }
        //globalVar.refreshMap.toggle()
    }
    
    func getDirections() async throws -> MKRoute  {
        route = nil
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: startingPoint))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: endingPoint))
        
        let directions = MKDirections(request: request)
        let response = try? await directions.calculate()
        route = response?.routes.first
        return route ?? MKRoute()
    }
    
    func removeLocation(at offsets: IndexSet) {
        for index in offsets {
            let location = locations[index]
            viewModel.moc.delete(location)
        }
        do {
            try viewModel.moc.save()
        } catch {
            print("Core Data Error")
        }
        //globalVar.refreshMap.toggle()
    }
    
    
    func getPlace(from address: AddressResult) {
        let request = MKLocalSearch.Request()
        let title = address.title
        let subtitle = address.subtitle
        
        request.naturalLanguageQuery = subtitle.contains(title)
        ? subtitle : title + ", " + subtitle
        
        Task {
            let response = try await MKLocalSearch(request: request).start()
            await MainActor.run {
                annotationItems = response.mapItems.map {
                    AnnotationItem(
                        name: $0.name ?? "",
                        title: $0.placemark.title ?? "",
                        subtitle: $0.placemark.subtitle ?? "",
                        latitude: $0.placemark.coordinate.latitude,
                        longitude: $0.placemark.coordinate.longitude
                    )
                }
                
                region = response.boundingRegion
                position = .region(region)
                results = response.mapItems
            }
        }
    }
}


#Preview {
    let context = DataController.preview
    let trips: [Trip]
    let requestTrips: NSFetchRequest<Trip> = Trip.fetchRequest()
    do {
        trips = try context.fetch(requestTrips)
    } catch {
        let nserror = error as NSError
        fatalError("Error \(nserror): \(nserror.userInfo)")
    }
    let trip = trips[1]
    return TripOverviewView(trip: trip).environment(\.managedObjectContext, DataController.preview)
}
 




