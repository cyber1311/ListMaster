//
//  ShareManagementView.swift
//  ListMaster
//
//  Created by Анастасия Доблер on 03.04.2024.
//

import Foundation
import SwiftUI

struct ShareManagementView: View {
    @State private var showErrorAlert = false
    @State private var alertMessage = ""
    @ObservedObject var listModel: ListModel
    @State var userInfo: UserInfo
    
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
                if userInfo.UserId == listModel.OwnerId{
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
            if userInfo.UserId == listModel.OwnerId{
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
        .alert(isPresented: $showErrorAlert) {
            Alert(title: Text("Ошибка"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .navigationTitle(listModel.Title)
        .onAppear{
            getAllListUsers()
        }
        .toolbar {
            if userInfo.UserId == listModel.OwnerId{
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
        let url = URL(string: "http://localhost:5211/lists/cancel_share_for_user?owner_id=\(userInfo.UserId.uuidString.lowercased())&user_id=\(userToDeleteId.uuidString.lowercased())&list_id=\(listModel.Id.uuidString.lowercased())")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer " + (userInfo.Token), forHTTPHeaderField: "Authorization")
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                DispatchQueue.main.async {
                    showErrorAlert = true
                    alertMessage = "Произошли технические неполадки"
                }
            } else if data != nil {
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
    
    }
    
    func deleteListShare(){
        let url = URL(string: "http://localhost:5211/lists/delete_list_share?user_id=\(userInfo.UserId.uuidString.lowercased())&list_id=\(listModel.Id.uuidString.lowercased())")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer " + (userInfo.Token), forHTTPHeaderField: "Authorization")
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                DispatchQueue.main.async {
                    showErrorAlert = true
                    alertMessage = "Произошли технические неполадки"
                }
            } else if data != nil {
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
    
    }
    
    func getAllListUsers(){
        let url = URL(string: "http://localhost:5211/lists/get_all_list_users?user_id=\(userInfo.UserId.uuidString.lowercased())&list_id=\(listModel.Id.uuidString.lowercased())")!

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer " + (userInfo.Token), forHTTPHeaderField: "Authorization")

        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                DispatchQueue.main.async {
                    showErrorAlert = true
                    alertMessage = "Произошли технические неполадки"
                }
            } else if let data = data {
                do{
                    if let httpResponse = response as? HTTPURLResponse{
                        if httpResponse.statusCode == 200{
                            let decoder = JSONDecoder()

                            userModel.users = try decoder.decode([GroupMember].self, from: data)
                            userModel.reload()
                        } else {
                            DispatchQueue.main.async {
                                showErrorAlert = true
                                alertMessage = "Произошли технические неполадки"
                            }
                        }
                    }
                }
                catch{
                    DispatchQueue.main.async {
                        showErrorAlert = true
                        alertMessage = "Произошли технические неполадки"
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
    }
    
    
}
