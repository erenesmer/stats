//
//  statsApp.swift
//  stats
//
//  Created by Eren Esmer on 7/28/25.
//

import SwiftUI

@main
struct statsApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
