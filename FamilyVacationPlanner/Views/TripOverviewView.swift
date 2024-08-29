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
    //@Environment(GlobalVariables.self) private var globalVar
    //@Environment(LocationsViewModel.self) private var viewModel
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
                NavigationLink("Date Array") {
                    DayLocationsView(trip: trip)
                        .toolbar(.hidden, for: .navigationBar)
                }
            }
            .padding()
            
        }
        .toolbar(.hidden, for: .navigationBar)
        
        .presentationDetents([.medium]) //.fraction(0.5), .medium])
        .interactiveDismissDisabled()
        .sheet(isPresented: $isPresented) {
            SearchDestinationView(trip: $trip, isPresented: $isPresented, locationType: $locationType, daySegments: .constant([Segment(segmentIndex: 0, dayDate: Date(), dayString: "", startLocation: Location(), endLocation: Location())]))
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
 




