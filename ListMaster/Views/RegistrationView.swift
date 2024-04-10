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
    @State private var goToMainView = false
    @State private var showErrorAlert = false
    @State private var alertMessage = ""
    
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
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .fullScreenCover(isPresented: $goToMainView) {
                NavigationView{
                    MainScreenView()
                }
            }
            .alert(isPresented: $showErrorAlert) {
                Alert(title: Text("Ошибка"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
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
            let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                if let data = data {
                    do{
                        if let httpResponse = response as? HTTPURLResponse{
                            if httpResponse.statusCode == 200{
                                let decoder = JSONDecoder()
                                let registrationResponse = try decoder.decode(RegistrationResponse.self, from: data)
                                let dateFormatter = DateFormatter()
                                dateFormatter.dateFormat = "dd.MM.yyyy HH:mm:ss"
                                let expiresAtDate = dateFormatter.date(from: registrationResponse.expiresAt)
                                DispatchQueue.main.async {
                                    UserDefaults.standard.set(true, forKey: "isUserLoggedIn")
                                    UserDefaults.standard.set(userId.uuidString, forKey: "UserId")
                                    UserDefaults.standard.set(userName, forKey: "UserName")
                                    UserDefaults.standard.set(userPassword, forKey: "UserPassword")
                                    UserDefaults.standard.set(userEmail, forKey: "UserEmail")
                                    UserDefaults.standard.set(registrationResponse.token, forKey: "Token")
                                    UserDefaults.standard.set(expiresAtDate, forKey: "TokenExpiresAt")
                                    goToMainView = true
                                }
                            } else if httpResponse.statusCode == 409{
                                DispatchQueue.main.async {
                                    alertMessage = "Пожалуйста, введите другую почту. Пользователь с такой почтой уже существует"
                                    showErrorAlert = true
                                }
                                
                            } else {
                                DispatchQueue.main.async {
                                    self.alertMessage = "Произошли технические неполадки"
                                    self.showErrorAlert = true
                                }
                            }
                        }
                    }
                    catch{
                        DispatchQueue.main.async {
                            self.alertMessage = "Произошли технические неполадки"
                            self.showErrorAlert = true
                        }
                    }
                    
                }else{
                    DispatchQueue.main.async {
                        self.alertMessage = "Произошли технические неполадки"
                        self.showErrorAlert = true
                    }
                }
            }
            
            task.resume()
        } catch {
            DispatchQueue.main.async {
                self.alertMessage = "Произошли технические неполадки"
                self.showErrorAlert = true
            }
        }
        
        
    }
}
