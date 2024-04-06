//
//  ShareManagementView.swift
//  ListMaster
//
//  Created by Анастасия Доблер on 03.04.2024.
//

import Foundation
import SwiftUI

struct ShareManagementView: View {
    @State private var showInternetErrorAlert = false
    @State private var showCommonErrorAlert = false
    @ObservedObject var listModel: ListModel
    @State private var userId: UUID = UUID()
    @State private var token: String = ""
    @ObservedObject var userModel: UserModel = UserModel()
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
  
    var body: some View {
        Form{
            Section(header: Text("Владелец списка")){
                if let index = userModel.users.firstIndex(where: { $0.id == listModel.OwnerId }) {
                    VStack(alignment: .leading){
                        Text(userModel.users[index].name).bold()
                        Text(userModel.users[index].email)
                    }
                }
                
            }
            Section(header: Text("Пользователи с доступом к этому списку")){
                if userId == listModel.OwnerId{
                    ForEach($userModel.users, id: \.id) { user in
                        if(user.wrappedValue.id != listModel.OwnerId){
                            VStack(alignment: .leading){
                                Text(user.wrappedValue.name).bold()
                                Text(user.wrappedValue.email)
                            }
                        }
                    }
                    .onDelete(perform: removeUserShare)
                }else{
                    ForEach($userModel.users, id: \.id) { user in
                        if(user.wrappedValue.id != listModel.OwnerId){
                            VStack(alignment: .leading){
                                Text(user.wrappedValue.name).bold()
                                Text(user.wrappedValue.email)
                            }
                        }
                    }
                }
                
            }
            if userId == listModel.OwnerId{
                Section {
                    HStack{
                        Spacer()
                        Button("Удалить общий доступ") {
                            deleteListShare()
                            self.presentationMode.wrappedValue.dismiss()
                        }
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        Spacer()
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
        .navigationTitle(listModel.Title)
        .onAppear{
            userId = UUID(uuidString: UserDefaults.standard.string(forKey: "UserId")!)!
            token = UserDefaults.standard.string(forKey: "Token")!
            getAllListUsers()
        }
        .toolbar {
            if userId == listModel.OwnerId{
                ToolbarItem {
                    EditButton()
                }
            }
        }
        .refreshable{
            getAllListUsers()
        }
        
    }
    
    func removeUserShare(at offsets: IndexSet) {
        for index in offsets {
            let user = userModel.users[index]
            cancelShareForUser(userToDeleteId: user.id)
        }
        userModel.users.remove(atOffsets: offsets)
    }
    
    
    func cancelShareForUser(userToDeleteId: UUID){
        let url = URL(string: "http://localhost:5211/lists/cancel_share_for_user?owner_id=\(userId.uuidString.lowercased())&user_id=\(userToDeleteId.uuidString.lowercased())&list_id=\(listModel.Id.uuidString.lowercased())")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
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
                        print("Some error")
                        showCommonErrorAlert = true
                    }
                }
            }else{
                print("Some error")
            }
        }
        
        task.resume()
    
    }
    
    func deleteListShare(){
        let url = URL(string: "http://localhost:5211/lists/delete_list_share?user_id=\(userId.uuidString.lowercased())&list_id=\(listModel.Id.uuidString.lowercased())")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
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
                        print("Some error")
                        showCommonErrorAlert = true
                    }
                }
            }else{
                print("Some error")
            }
        }
        
        task.resume()
    
    }
    
    func getAllListUsers(){
        let url = URL(string: "http://localhost:5211/lists/get_all_list_users?user_id=\(userId.uuidString.lowercased())&list_id=\(listModel.Id.uuidString.lowercased())")!

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer " + (token), forHTTPHeaderField: "Authorization")

        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                showInternetErrorAlert = true
                print("Error: \(error)")
            } else if let data = data {
                do{
                    if let httpResponse = response as? HTTPURLResponse{
                        if httpResponse.statusCode == 200{
                            let decoder = JSONDecoder()

                            userModel.users = try decoder.decode([GroupMember].self, from: data)
                            userModel.reload()
                            showCommonErrorAlert = false
                            showInternetErrorAlert = false
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
