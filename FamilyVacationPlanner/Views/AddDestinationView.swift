//
//  AddDestination.swift
//  FamilyVacationPlanner
//
//  Created by David Steele on 6/21/24.
//

import MapKit
import SwiftUI

struct AddDestinationView: View {

    
    let selection: MKMapItem = MKMapItem()
    
    @State private var annotationItem: AnnotationItem = AnnotationItem(name: "My House", title: "201 Whitetail Ridge", subtitle: "Hudson, IA 50643", latitude: 42.0, longitude: -92.0)

    
    @State private var position: MapCameraPosition = .automatic
    @Binding var results: [AnnotatedMapItem]
    @State private var selectedResult: AnnotatedMapItem?
    @State private var region = MKCoordinateRegion()
    @State private var annotationItems: [AnnotationItem] = []
    
    @State private var setUpViewIsPresented = false
    


    var body: some View {
        Map(position: $position, selection: $selectedResult) {
            ForEach (results, id: \.self) { item in
                Marker(item: item.item)
            }
        }
        .onAppear() {
            print("ResultsCount: \(results.count)")
            print("ResultName: \(String(describing: results.first?.item.name))")
            if results.count == 1 {position = .region(MKCoordinateRegion(center: results.first?.item.placemark.coordinate ?? CLLocationCoordinate2D(), span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)))
            } else {
                position = .automatic
            }
        }
        
        
        .onChange(of: selectedResult?.item ?? MKMapItem()) {
            annotationItem.name = selectedResult?.item.name ?? ""
            annotationItem.title = selectedResult?.item.placemark.title ?? ""
            annotationItem.subtitle = selectedResult?.item.placemark.subtitle ?? ""
            annotationItem.latitude = selectedResult?.item.placemark.coordinate.latitude ?? 0.0
            annotationItem.longitude = selectedResult?.item.placemark.coordinate.longitude ?? 0.0
            print(annotationItem.name)
            print(annotationItem.title)
            if (selectedResult != nil) {
                setUpViewIsPresented.toggle()
            }
        }
        
        .sheet(isPresented: $setUpViewIsPresented) {
            DestinationSetUpView(annotationItem: $annotationItem)
        }
        
        
        .presentationDetents([.medium, .large, .fraction(0.2)]) //.fraction(0.5), .medium])            
        
    }
}



//#Preview {
//    let sampleItem1 = AnnotatedMapItem(item: MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: 37.7833, longitude: -122.4167), addressDictionary: nil)))
//    let sampleItem2 = AnnotatedMapItem(item: MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: 37.8000, longitude: -122.4000), addressDictionary: nil)))
//
//    let isPresented = false
//    let trip = Trip()
//    let locationType: LocationType = .startLocation
//    let locationsForDay = [Segment(segmentIndex: 0, dayDate: Date(), dayString: "Today", startLocation: Location(), endLocation: Location())]
//        
//    return AddDestinationView(results: .constant([sampleItem1, sampleItem2]), trip: .constant(trip), isPresented: .constant(isPresented), locationType: .constant(locationType), daySegments: .constant(locationsForDay)).environment(\.managedObjectContext, DataController.preview)
//}

