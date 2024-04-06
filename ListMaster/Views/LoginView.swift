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
    @State private var showErrorAlert = false
    @State private var alertMessage = ""

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
            }
            .fullScreenCover(isPresented: $conditionIsMet) {
                MainScreenView()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .padding()
            
            NavigationLink(destination: RegistrationView()) {
                Text("Зарегистрироваться")
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .navigationTitle("Вход")
        .navigationBarBackButtonHidden(true)
        .alert(isPresented: $showErrorAlert) {
            Alert(title: Text("Ошибка"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }
    
    func loginUserForServer(){
        let url = URL(string: "http://localhost:5211/users/sign_in?email=\(userEmail)&password=\(userPassword)")!

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                DispatchQueue.main.async {
                    self.alertMessage = "Проверьте подключение к интернету"
                    self.showErrorAlert = true
                    print("Error: \(error)")
                }
            } else if let data = data {
                do{
                    if let httpResponse = response as? HTTPURLResponse{
                        if httpResponse.statusCode == 200{
                            let decoder = JSONDecoder()
                            let loginResponse = try decoder.decode(LoginResponse.self, from: data)
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = "dd.MM.yyyy HH:mm:ss"
                            let expiresAtDate = dateFormatter.date(from: loginResponse.expiresAt)
                            DispatchQueue.main.async {
                                UserDefaults.standard.set(true, forKey: "isUserLoggedIn")
                                UserDefaults.standard.set(loginResponse.id.uuidString, forKey: "UserId")
                                UserDefaults.standard.set(loginResponse.name, forKey: "UserName")
                                UserDefaults.standard.set(userPassword, forKey: "UserPassword")
                                UserDefaults.standard.set(userEmail, forKey: "UserEmail")
                                UserDefaults.standard.set(loginResponse.token, forKey: "Token")
                                UserDefaults.standard.set(expiresAtDate, forKey: "TokenExpiresAt")
                                conditionIsMet = true
                            }
                        } else if httpResponse.statusCode == 404{
                            DispatchQueue.main.async {
                                self.alertMessage = "Неверная почта или пароль"
                                self.showErrorAlert = true
                            }
                        } else {
                            DispatchQueue.main.async {
                                self.alertMessage = "Произошли технические неполадки. Попробуйте еще раз ввести данные"
                                self.showErrorAlert = true
                            }
                        }
                    }
                }
                catch{
                    DispatchQueue.main.async {
                        self.alertMessage = "Произошли технические неполадки. Попробуйте еще раз ввести данные"
                        self.showErrorAlert = true
                    }
                }
            }else{
                DispatchQueue.main.async {
                    self.alertMessage = "Произошли технические неполадки. Попробуйте еще раз ввести данные"
                    self.showErrorAlert = true
                }
            }
        }
        
        task.resume()
    }
}
