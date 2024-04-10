//
//  ContentView.swift
//  ListMaster
//
//  Created by Анастасия Доблер on 09.02.2024.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("isUserLoggedIn") private var isUserLoggedIn = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView{
            if isUserLoggedIn, let expiresAt = UserDefaults.standard.object(forKey: "TokenExpiresAt") as? Date, expiresAt.compare(Date()) == .orderedDescending {
                MainScreenView()
            } else {
                LoginView()
            }
                
        }
        .onAppear{
            if Reachability.isConnectedToNetwork() == false {
                showAlert = true
                alertMessage = "Отсутствует подключение к интернету"
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Ошибка"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        
        
    }
    

}
