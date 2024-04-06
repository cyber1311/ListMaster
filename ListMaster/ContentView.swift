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
    @State var userInfo: UserInfo? = nil
    
    var body: some View {
        NavigationView{
            if isUserLoggedIn {
                MainScreenView()
            } else {
                LoginView()
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Ошибка"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .onAppear{
            if Reachability.isConnectedToNetwork() {
                if isUserLoggedIn{
                    if let name = UserDefaults.standard.object(forKey: "UserName") as? String,
                        let email = UserDefaults.standard.object(forKey: "UserEmail") as? String,
                        let password = UserDefaults.standard.object(forKey: "UserPassword") as? String,
                        let token = UserDefaults.standard.object(forKey: "Token") as? String,
                        let id = UserDefaults.standard.object(forKey: "UserId") as? String,
                        let token_expires_at = UserDefaults.standard.object(forKey: "TokenExpiresAt") as? Date {
                        userInfo = UserInfo(user_id: UUID(uuidString: id)!, user_email: email, user_name: name, user_password: password, token: token, token_expires_at: token_expires_at)
                    }
                    else{
                        showAlert = true
                        alertMessage = "Произошла ошибка"
                    }
                }
            } else {
                showAlert = true
                alertMessage = "Отсутствует подключение к интернету"
            }
        }
        
    }
    

}
