//
//  RegistrationView.swift
//  ListMaster
//
//  Created by Анастасия Доблер on 09.02.2024.
//

import SwiftUI

struct RegistrationView: View {
    @State private var userName = ""
    @State private var userEmail = ""
    @State private var userPassword = ""
    @State private var conditionIsMet = false
    @State private var showUserExistErrorAlert = false
    @State private var showCommonErrorAlert = false
    @State private var showInternetErrorAlert = false
    
    var body: some View {
        VStack {
            TextField("Имя", text: $userName)
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            TextField("Почта", text: $userEmail)
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            SecureField("Пароль", text: $userPassword)
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            Button(action:{
                let userId = UUID()
                registerUserToServer(userId: userId)
                
            }) {
                Text("Зарегистрироваться")
            }.fullScreenCover(isPresented: $conditionIsMet) {
                MainScreenView()
            }
            .alert(isPresented: $showUserExistErrorAlert) {
                Alert(title: Text("Ошибка"), message: Text("Пожалуйста, введите другую почту. Пользователь с такой почтой уже существует"), dismissButton: .default(Text("OK")))
            }.alert(isPresented: $showCommonErrorAlert) {
                Alert(title: Text("Ошибка"), message: Text("Произошли технические неполадки. Попробуйте еще раз ввести данные"), dismissButton: .default(Text("OK")))
            }.alert(isPresented: $showInternetErrorAlert) {
                Alert(title: Text("Ошибка"), message: Text("Проверьте подключение к интернету"), dismissButton: .default(Text("OK")))
            }
            .padding()
        }
        .padding()
        .navigationTitle("Регистрация")
    }
    
    func registerUserToServer(userId: UUID){
        let user = User(id: userId, email: userEmail, name: userName, password: userPassword)
        
        let url = URL(string: "http://localhost:5211/users/add_user")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let jsonData = try JSONEncoder().encode(user)
            request.httpBody = jsonData
        } catch {
            print("Error encoding user: \(error)")
        }
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                showInternetErrorAlert = true
                print("Error: \(error)")
            } else if let data = data {
                do{
                    if let httpResponse = response as? HTTPURLResponse{
                        if httpResponse.statusCode == 200{
                            let decoder = JSONDecoder()
                            let registrationResponse = try decoder.decode(RegistrationResponse.self, from: data)
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = "dd.MM.yyyy HH:mm:ss"
                            let expiresAtDate = dateFormatter.date(from: registrationResponse.expiresAt)
                            print("Token: \(registrationResponse.token)")
                            print("Expires At: \(registrationResponse.expiresAt)")
                            UserDefaults.standard.set(true, forKey: "isUserLoggedIn")
                            UserDefaults.standard.set(userId.uuidString, forKey: "UserId")
                            UserDefaults.standard.set(userName, forKey: "UserName")
                            UserDefaults.standard.set(userPassword, forKey: "UserPassword")
                            UserDefaults.standard.set(userEmail, forKey: "UserEmail")
                            UserDefaults.standard.set(registrationResponse.token, forKey: "Token")
                            UserDefaults.standard.set(expiresAtDate, forKey: "TokenExpiresAt")
                            conditionIsMet = true
                            showUserExistErrorAlert = false
                            showCommonErrorAlert = false
                            showInternetErrorAlert = false
                        } else if httpResponse.statusCode == 409{
                            print("Пользователь с такой почтой уже существует")
                            showUserExistErrorAlert = true
                        } else {
                            print("Some error")
                            showCommonErrorAlert = true
                        }
                    }
                }
                catch{
                    print("Some error")
                }
                
            }else{
                print("Some error")
            }
        }
        
        task.resume()
    }
}
