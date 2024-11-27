//
//  BackLog.swift
//  FamilyVacationPlanner
//
//  Created by David Steele on 8/17/24.
//

import Foundation

/*
 
 1. When shifting sheet detent update the mapView
 .presentationDetents([.fraction(0.15), .medium, .large], selection: $detentBinding))
 
 Three ways to select a location:
 
 1. Type location in search bar:
    1. Searches for address of Location name (SearchModel class)
        Uses the region of Map shown
    2. Populates list
    3. User selects from list (AddressResult)
    4. Runs GetPlace, provides searchresults ([AnnotatedMapItem])
    5. Onchange of Results:
        searchResults updated
        Camera Postion updated to show results on Map
    6. User selects Marker from Map.
 
 2. Select location on Map
    1. ontap get coordinates (locationFromMap: AnnotationItem)
    2. getLocationPlacemark to get Location Name (address etc) (AnnotatedMapItem)
    3. appends searchResults
    4. updates globalVars.location from Map
    
 
 3. Selecte a Recent location
 
 
 There are 2 places to populate data:
  1. Need to show location on Map
  2. Need to set up Location Object

 
    
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 */
