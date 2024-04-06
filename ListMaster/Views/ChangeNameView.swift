//
//  ChangeNameView.swift
//  ListMaster
//
//  Created by Анастасия Доблер on 25.03.2024.
//

import Foundation
import SwiftUI

struct ChangeNameView: View {
    @State private var showInternetErrorAlert = false
    @State private var showCommonErrorAlert = false
    
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @State private var newName: String = ""
  
    var body: some View {
        Form {
            Section(header: Text("Изменение имя")) {
                TextField("Новое имя", text: $newName)
            }
            
            Section {
                HStack{
                    Spacer()
                    Button("Сохранить") {
                        updateNameForServer()
                        UserDefaults.standard.set(newName, forKey: "UserName")
                        self.presentationMode.wrappedValue.dismiss()
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    Spacer()
                }
                .alert(isPresented: $showInternetErrorAlert) {
                    Alert(title: Text("Ошибка"), message: Text("Проверьте подключение к интернету"), dismissButton: .default(Text("OK")))
                }
                .alert(isPresented: $showCommonErrorAlert) {
                    Alert(title: Text("Ошибка"), message: Text("Произошли технические неполадки"), dismissButton: .default(Text("OK")))
                }
            }
        }
        
        .navigationTitle("Профиль")
        
    }
    
    func updateNameForServer(){
        do{
            let userId = UUID(uuidString: UserDefaults.standard.string(forKey: "UserId") ?? "")
            
            let userUpdateNameRequest = UserUpdateNameRequest(id: userId!, name: newName)
            
            let token = UserDefaults.standard.string(forKey: "Token")
            
            let url = URL(string: "http://localhost:5211/users/update_user_name")!

            var request = URLRequest(url: url)
            request.httpMethod = "PUT"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("Bearer " + (token ?? ""), forHTTPHeaderField: "Authorization")
            
            let jsonData = try JSONEncoder().encode(userUpdateNameRequest)
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
                            UserDefaults.standard.set(newName, forKey: "UserName")
                            self.presentationMode.wrappedValue.dismiss()
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
