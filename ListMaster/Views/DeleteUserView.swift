//
//  DeleteUserView.swift
//  ListMaster
//
//  Created by Анастасия Доблер on 05.04.2024.
//

import Foundation
import SwiftUI

struct DeleteUserView: View {
    @State private var showInternetErrorAlert = false
    @State private var showCommonErrorAlert = false
    @State private var showPasswordErrorAlert = false
    @State private var conditionIsMet = false
    
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
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
                        if let userPassword = UserDefaults.standard.object(forKey: "UserPassword") as? String {
                            if password == userPassword{
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
                                showPasswordErrorAlert = true
                            }
                            
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
        .alert(isPresented: $showInternetErrorAlert) {
            Alert(title: Text("Ошибка"), message: Text("Проверьте подключение к интернету"), dismissButton: .default(Text("OK")))
        }
        .alert(isPresented: $showCommonErrorAlert) {
            Alert(title: Text("Ошибка"), message: Text("Произошли технические неполадки"), dismissButton: .default(Text("OK")))
        }
        .alert(isPresented: $showPasswordErrorAlert) {
            Alert(title: Text("Ошибка"), message: Text(" Пароль неверен"), dismissButton: .default(Text("OK")))
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
            if let error = error {
                showInternetErrorAlert = true
                print("Error: \(error)")
            } else if data != nil {
                if let httpResponse = response as? HTTPURLResponse{
                    if httpResponse.statusCode == 200{
                        showCommonErrorAlert = false
                        showInternetErrorAlert = false
                    } else {
                        print("Some error \(httpResponse.statusCode)")
                        showCommonErrorAlert = true
                    }
                }
            }else{
                print("Some error")
            }
        }
        
        task.resume()
    }

    
}




