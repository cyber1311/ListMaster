//
//  DeleteUserView.swift
//  ListMaster
//
//  Created by Анастасия Доблер on 05.04.2024.
//

import Foundation
import SwiftUI

struct DeleteUserView: View {
    @State private var showErrorAlert = false
    @State private var alertMessage = ""
    @State private var conditionIsMet = false
    @State var userInfo: UserInfo
    @State private var password: String = ""
  
    var body: some View {
        Form {
            Section(header: Text("Введите пароль")) {
                SecureField("Пароль", text: $password)
            }
            
            Section {
                HStack{
                    Spacer()
                    Button("Удалить аккаунт") {
                        if password == userInfo.UserPassword{
                            deleteUser()
                            UserDefaults.standard.removeObject(forKey: "isUserLoggedIn")
                            UserDefaults.standard.removeObject(forKey: "UserId")
                            UserDefaults.standard.removeObject(forKey: "UserName")
                            UserDefaults.standard.removeObject(forKey: "UserPassword")
                            UserDefaults.standard.removeObject(forKey: "UserEmail")
                            UserDefaults.standard.removeObject(forKey: "Token")
                            UserDefaults.standard.removeObject(forKey: "TokenExpiresAt")
                            conditionIsMet = true
                            
                        }else{
                            showErrorAlert = true
                            alertMessage = "Пароль неверен"
                        }
                    }
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    Spacer()
                }
            }
        }
        .alert(isPresented: $showErrorAlert) {
            Alert(title: Text("Ошибка"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .navigationTitle("Профиль")
        .fullScreenCover(isPresented: $conditionIsMet) {
            ContentView()
        }
    }
    
    
    func deleteUser() {
        let userId = UserDefaults.standard.string(forKey: "UserId")!
        let url = URL(string: "http://localhost:5211/users/delete_user?user_id=\(userId.lowercased())")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let token = UserDefaults.standard.string(forKey: "Token")!
        request.addValue("Bearer " + (token), forHTTPHeaderField: "Authorization")

        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if data != nil {
                if let httpResponse = response as? HTTPURLResponse{
                    if httpResponse.statusCode != 200{
                        DispatchQueue.main.async {
                            showErrorAlert = true
                            alertMessage = "Произошли технические неполадки"
                        }
                    }
                }
            }else{
                DispatchQueue.main.async {
                    showErrorAlert = true
                    alertMessage = "Произошли технические неполадки"
                }
            }
        }
        
        task.resume()
    }

    
}




