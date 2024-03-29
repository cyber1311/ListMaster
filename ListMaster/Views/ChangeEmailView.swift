//
//  ChangeEmailView.swift
//  ListMaster
//
//  Created by Анастасия Доблер on 25.03.2024.
//

import Foundation
import SwiftUI

struct ChangeEmailView: View {
    @State private var showInternetErrorAlert = false
    @State private var showCommonErrorAlert = false
    
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @State private var newEmail: String = ""
  
    var body: some View {
        Form {
            Section(header: Text("Изменение электронной почты")) {
                TextField("Новая электронная почта", text: $newEmail)
            }
            .padding()
            
            Section {
                Button("Сохранить") {
                    updateEmailForServer()
                    if showInternetErrorAlert == false && showCommonErrorAlert == false{
                        UserDefaults.standard.set(newEmail, forKey: "UserEmail")
                        self.presentationMode.wrappedValue.dismiss()
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
        .navigationTitle("Профиль")
        
    }
    
    func updateEmailForServer(){
        do{
            let userId = UUID(uuidString: UserDefaults.standard.string(forKey: "UserId") ?? "")
            
            let userUpdateEmailRequest = UserUpdateEmailRequest(id: userId!, email: newEmail)
            
            let token = UserDefaults.standard.string(forKey: "Token")
            
            let url = URL(string: "http://localhost:5211/users/update_user_email")!

            var request = URLRequest(url: url)
            request.httpMethod = "PUT"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("Bearer " + (token ?? ""), forHTTPHeaderField: "Authorization")
            
            let jsonData = try JSONEncoder().encode(userUpdateEmailRequest)
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
                    showInternetErrorAlert = true
                    print("Some error")
                }
            }
            
            task.resume()
        }catch{
            print("Error")
        }
    }
    
    
    
}
