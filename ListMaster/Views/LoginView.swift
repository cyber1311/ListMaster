//
//  LoginView.swift
//  ListMaster
//
//  Created by Анастасия Доблер on 09.02.2024.
//

import Foundation
import SwiftUI

struct LoginView: View {
    @State private var userEmail = ""
    @State private var userPassword = ""
    @State private var conditionIsMet = false
    @State private var showUserNotExistErrorAlert = false
    @State private var showCommonErrorAlert = false
    @State private var showInternetErrorAlert = false

    var body: some View {
        VStack {
            TextField("Почта", text: $userEmail)
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())

            SecureField("Пароль", text: $userPassword)
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())
            Button(action:{
                loginUserForServer()

            }) {
                Text("Войти")
            }.fullScreenCover(isPresented: $conditionIsMet) {
                MainScreenView()
            }.padding()
            .alert(isPresented: $showUserNotExistErrorAlert) {
                Alert(title: Text("Ошибка"), message: Text("Неверная почта или пароль"), dismissButton: .default(Text("OK")))
            }.alert(isPresented: $showCommonErrorAlert) {
                Alert(title: Text("Ошибка"), message: Text("Произошли технические неполадки. Попробуйте еще раз ввести данные"), dismissButton: .default(Text("OK")))
            }.alert(isPresented: $showInternetErrorAlert) {
                Alert(title: Text("Ошибка"), message: Text("Проверьте подключение к интернету"), dismissButton: .default(Text("OK")))
            }

            NavigationLink(destination: RegistrationView()) {
                Text("Зарегистрироваться")
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .navigationTitle("Вход")
    
    }
    
    func loginUserForServer(){
        let url = URL(string: "http://localhost:5211/users/sign_in?email=\(userEmail)&password=\(userPassword)")!

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                showInternetErrorAlert = true
                print("Error: \(error)")
            } else if let data = data {
                do{
                    if let httpResponse = response as? HTTPURLResponse{
                        if httpResponse.statusCode == 200{
                            let decoder = JSONDecoder()
                            let loginResponse = try decoder.decode(LoginResponse.self, from: data)
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = "dd.MM.yyyy HH:mm:ss"
                            let expiresAtDate = dateFormatter.date(from: loginResponse.expiresAt)
                            print("Token: \(loginResponse.token)")
                            print("Expires At: \(loginResponse.expiresAt)")
                            UserDefaults.standard.set(true, forKey: "isUserLoggedIn")
                            UserDefaults.standard.set(loginResponse.id.uuidString, forKey: "UserId")
                            UserDefaults.standard.set(loginResponse.name, forKey: "UserName")
                            UserDefaults.standard.set(userPassword, forKey: "UserPassword")
                            UserDefaults.standard.set(userEmail, forKey: "UserEmail")
                            UserDefaults.standard.set(loginResponse.token, forKey: "Token")
                            UserDefaults.standard.set(expiresAtDate, forKey: "TokenExpiresAt")
                            conditionIsMet = true
                            showUserNotExistErrorAlert = false
                            showCommonErrorAlert = false
                            showInternetErrorAlert = false
                        } else if httpResponse.statusCode == 404{
                            print("Такого пользователя не существует")
                            showUserNotExistErrorAlert = true
                        } else {
                            print("Bad status code")
                            showCommonErrorAlert = true
                        }
                    }
                }
                catch{
                    print("No data")
                }
                
            }else{
                print("Some error")
            }
        }
        
        task.resume()
    }
}
