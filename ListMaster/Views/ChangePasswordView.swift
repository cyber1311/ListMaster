//
//  ChangePasswordView.swift
//  ListMaster
//
//  Created by Анастасия Доблер on 25.03.2024.
//

import Foundation
import SwiftUI

struct ChangePasswordView: View {
    @State private var showInternetErrorAlert = false
    @State private var showCommonErrorAlert = false
    @State private var showPasswordErrorAlert = false
    
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @State private var oldPassword: String = ""
    @State private var newPassword: String = ""
  
    var body: some View {
        Form {
            Section(header: Text("Изменение пароля")) {
                TextField("Старый пароль", text: $oldPassword)
                    .padding()
                TextField("Новый пароль", text: $newPassword)
                
            }
            .padding()
            
            Section {
                Button("Сохранить") {
                    if let password = UserDefaults.standard.object(forKey: "UserPassword") as? String {
                        if password == oldPassword{
                            showPasswordErrorAlert = false
                            updatePasswordForServer()
                            UserDefaults.standard.set(newPassword, forKey: "UserPassword")
                            self.presentationMode.wrappedValue.dismiss()
                        }else{
                            showPasswordErrorAlert = true
                        }
                        
                    }
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
            Alert(title: Text("Ошибка"), message: Text("Старый пароль неверен"), dismissButton: .default(Text("OK")))
        }
        .navigationTitle("Профиль")
        
    }
    
    func updatePasswordForServer(){
        do{
            let userId = UUID(uuidString: UserDefaults.standard.string(forKey: "UserId") ?? "")
            
            let userUpdatePasswordRequest = UserUpdatePasswordRequest(id: userId!, password: newPassword)
            
            let token = UserDefaults.standard.string(forKey: "Token")
            
            let url = URL(string: "http://localhost:5211/users/update_user_password")!

            var request = URLRequest(url: url)
            request.httpMethod = "PUT"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("Bearer " + (token ?? ""), forHTTPHeaderField: "Authorization")
            
            let jsonData = try JSONEncoder().encode(userUpdatePasswordRequest)
            request.httpBody = jsonData
            
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
                            print("Some error")
                            showCommonErrorAlert = true
                        }
                    }
                    
                }else{
                    print("Some error")
                }
            }
            
            task.resume()
        }catch{
            print("Error")
        }
    }
    
    
    
}
