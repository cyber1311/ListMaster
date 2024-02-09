//
//  ListMasterApp.swift
//  ListMaster
//
//  Created by Анастасия Доблер on 09.02.2024.
//

import SwiftUI

@main
struct ListMasterApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            NavigationView{
                ContentView()
            }
            .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
