//
//  SearchModel.swift
//  FamilyVacationPlanner
//
//  Created by David Steele on 6/20/24.
//
import Foundation
import MapKit

@Observable
class SearchModel: NSObject, MKLocalSearchCompleterDelegate {
    var searchText = ""
    var locationResult: [AddressResult] = []
    
    
    let completer = MKLocalSearchCompleter()
    
    override init() {
        super.init()
        completer.delegate = self
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        locationResult = completer.results.map {
            AddressResult(title: $0.title, subtitle: $0.subtitle)
        }
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print(error.localizedDescription)
    }
}


