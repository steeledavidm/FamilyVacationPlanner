//
//  CoreDataiCloudExample.swift
//  FamilyVacationPlanner
//
//  Created by David Steele on 6/21/24.
//

import CoreData
import MapKit
import SwiftUI
import Foundation

struct CoreDataiCloudExample : View {
    
    @Environment(\.managedObjectContext) var moc
    @FetchRequest(sortDescriptors: [SortDescriptor(\.name)])
        var locations: FetchedResults<Location>
    
    var backgroundColor: Color = Color.init(uiColor: . systemGray6)
    
    
    var body: some View {
        NavigationStack {
            VStack {
                List {
                    ForEach(locations) { location in
                        VStack {
                            Text(location.name ?? "Unknown")
                            Text(location.title ?? "Unknown")
                        }
                    }
                    .onDelete(perform: removeLocation)
                }
                
                Button("Add") {
                    let names = ["Home", "Work", "School"]
                    let titles = ["RR2 Box 80", "201 Whitetail Ridge"]
                    
                    let chosenName = names.randomElement()!
                    let chosentitle = titles.randomElement()!
                    
                    let location = Location(context: moc)
                    location.id = UUID()
                    location.name = chosenName
                    location.title = chosentitle
                    
                    try? moc.save()
                }
            }
            .toolbar {
                EditButton()
            }
        }
    }
    
    func removeLocation(at offsets: IndexSet) {
        for index in offsets {
            let location = locations[index]
            moc.delete(location)
        }
        do {
            try moc.save()
        } catch {
            print("Core Data Error")
        }
    }
}

#Preview {
    CoreDataiCloudExample()
}
