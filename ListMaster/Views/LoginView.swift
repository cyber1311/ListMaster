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
    @State private var goToMainView = false
    @State private var showErrorAlert = false
    @State private var alertMessage = ""

    @State private var showValidationWindow = false
    @State private var verificationCode = ""
    @State private var verificationCodeFromServer = ""
    @State private var showIncorrectCodeAlert = false
    
    @State private var showEmailWindow = false
    @State private var forgetEmail = ""
    @State private var forgetNewPassword = ""
    @State private var showPasswordWindow = false
    
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
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .padding()
            .fullScreenCover(isPresented: $goToMainView) {
                NavigationView{
                    MainScreenView()
                }
                
            }
            
            Button(action:{
                showEmailWindow = true
            }) {
                Text("Забыли пароль?")
            }
            .padding()
            .alert("Восстановление пароля", isPresented: $showEmailWindow, actions: {
                TextField("Почта", text: $forgetEmail)
                Button("Ок", action: {
                    forgetPassword()
                })
                Button("Отмена", role: .cancel, action: {
                    forgetEmail = ""
                })
            }, message: {
                Text("Введите почту, на которую зарегистрирован аккаунт")
            })
            .alert("Код проверки", isPresented: $showValidationWindow, actions: {
                TextField("Код", text: $verificationCode)
                Button("Ок", action: {
                    if verificationCode == verificationCodeFromServer && verificationCodeFromServer != ""{
                        showPasswordWindow = true
                    }else{
                        verificationCode = ""
                        forgetEmail = ""
                        showIncorrectCodeAlert = true
                    }
                    
                })
                Button("Отмена", role: .cancel, action: {})
            }, message: {
                Text("На вашу почту отправлено письмо с проверочным кодом. Введите код из письма")
            })
            .alert(isPresented: $showIncorrectCodeAlert, content: {
                Alert(title: Text("Ошибка"), message: Text("Неверный код проверки. Попробуйте снова."), dismissButton: .default(Text("Ок")))
            })
            .alert("Восстановление пароля", isPresented: $showPasswordWindow, actions: {
                TextField("Новый пароль", text: $forgetNewPassword)
                Button("Ок", action: {
                    restoreAccess()
                })
                Button("Отмена", role: .cancel, action: {
                    verificationCode = ""
                    forgetEmail = ""
                    forgetNewPassword = ""
                })
            }, message: {
                Text("Введите новый пароль")
            })
            
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
    
    func forgetPassword(){
        let url = URL(string: "http://localhost:5211/users/forget_password?email=\(forgetEmail.lowercased())")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let data = data {
                do{
                    if let httpResponse = response as? HTTPURLResponse{
                        if httpResponse.statusCode == 200{
                            let decoder = JSONDecoder()
                            let response = try decoder.decode(VerificationResponse.self, from: data)
                            verificationCodeFromServer = response.verificationCode
                            DispatchQueue.main.async {
                                showValidationWindow = true
                            }
                        } else if httpResponse.statusCode == 404{
                            DispatchQueue.main.async {
                                alertMessage = "Такого пользователя не существует"
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
    }
    
    func restoreAccess(){
        let url = URL(string: "http://localhost:5211/users/restore_access?email=\(forgetEmail.lowercased())&password=\(forgetNewPassword)")!

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let data = data {
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
                                UserDefaults.standard.set(forgetNewPassword, forKey: "UserPassword")
                                UserDefaults.standard.set(forgetEmail.lowercased(), forKey: "UserEmail")
                                UserDefaults.standard.set(loginResponse.token, forKey: "Token")
                                UserDefaults.standard.set(expiresAtDate, forKey: "TokenExpiresAt")
                                goToMainView = true
                            }
                            
                        } else if httpResponse.statusCode == 404{
                            DispatchQueue.main.async {
                                self.alertMessage = "Неверная почта или пароль"
                                self.showErrorAlert = true
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
    }
    
    func loginUserForServer(){
        let url = URL(string: "http://localhost:5211/users/sign_in?email=\(userEmail.lowercased())&password=\(userPassword)")!

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let data = data {
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
                                UserDefaults.standard.set(userEmail.lowercased(), forKey: "UserEmail")
                                UserDefaults.standard.set(loginResponse.token, forKey: "Token")
                                UserDefaults.standard.set(expiresAtDate, forKey: "TokenExpiresAt")
                                goToMainView = true
                            }
                            
                        } else if httpResponse.statusCode == 404{
                            DispatchQueue.main.async {
                                self.alertMessage = "Неверная почта или пароль"
                                self.showErrorAlert = true
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
    }
}
