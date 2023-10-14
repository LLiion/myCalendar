//
//  MinKalenderApp.swift
//  MinKalender
//
//  Created by Lottis on 2023-10-14.
//

import SwiftUI

@main
struct MinKalenderApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
