//
//  ContentView.swift
//  ListMaster
//
//  Created by Анастасия Доблер on 09.02.2024.
//

import SwiftUI

struct ContentView: View {
    
    @AppStorage("isUserLoggedIn") private var isUserLoggedIn = false

    var body: some View {
        NavigationView {
            if isUserLoggedIn {
                MainScreenView()
            } else {
                LoginView()
            }
        }
        .onAppear {
            if UserDefaults.standard.bool(forKey: "isUserLoggedIn") {
                isUserLoggedIn = true
            }
        }
    }
}

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
