//
//  ChangePasswordView.swift
//  ListMaster
//
//  Created by Анастасия Доблер on 25.03.2024.
//

import Foundation
import SwiftUI

struct ChangePasswordView: View {
    @State private var showErrorAlert = false
    @State private var alertMessage = ""
    @State var userInfo: UserInfo
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @State private var oldPassword: String = ""
    @State private var newPassword: String = ""
  
    var body: some View {
        Form {
            Section(header: Text("Изменение пароля")) {
                SecureField("Старый пароль", text: $oldPassword)
                SecureField("Новый пароль", text: $newPassword)
                
            }
            
            Section {
                HStack{
                    Spacer()
                    Button("Сохранить") {
                        if userInfo.UserPassword == oldPassword{
                            updatePasswordForServer()
                            UserDefaults.standard.set(newPassword, forKey: "UserPassword")
                            self.presentationMode.wrappedValue.dismiss()
                        }else{
                            showErrorAlert = true
                            alertMessage = "Старый пароль неверен"
                        }
                    }
                    .padding()
                    .background(Color.blue)
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
        
    }
    
    func updatePasswordForServer(){
        do{
            let userUpdatePasswordRequest = UserUpdatePasswordRequest(id: userInfo.UserId, password: newPassword)
            
            let url = URL(string: "http://localhost:5211/users/update_user_password")!

            var request = URLRequest(url: url)
            request.httpMethod = "PUT"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("Bearer " + (userInfo.Token), forHTTPHeaderField: "Authorization")
            
            let jsonData = try JSONEncoder().encode(userUpdatePasswordRequest)
            request.httpBody = jsonData
            
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
        }catch{
            print("Error")
        }
    }
    
    
    
}
