//
//  ShareListView.swift
//  ListMaster
//
//  Created by Анастасия Доблер on 01.04.2024.
//

import Foundation
import SwiftUI

struct ShareListView: View {
    @State private var showInternetErrorAlert = false
    @State private var showCommonErrorAlert = false
    @State private var showUserNotExistErrorAlert = false
    @State private var newUserEmail = ""
    @State private var share = false
    @State private var forGroup = false
    @State public var listId: UUID
    @State private var userId: UUID = UUID()
    @State private var token: String = ""
    @ObservedObject var groupModel: GroupModel = GroupModel()
    @State var selectedGroup: Group = Group(id: UUID(), title: "Не выбрана", owner_id: UUID())
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
  
    var body: some View {
        NavigationView{
            Form{
                if groupModel.groups.count > 0{
                    Toggle("Для группы", isOn: $forGroup)
                }
                if forGroup == true{
                    Picker("Группа", selection: $selectedGroup) {
                        ForEach(groupModel.groups, id: \.self) { group in
                            Text(group.title).tag(group as Group?)
                        }
                    }
                    .pickerStyle(.menu)
                    
                }
                else{
                    Section {
                        TextField("Почта пользователя", text: $newUserEmail)
                    }
                }
                Toggle("Предоставить доступ к редактированию", isOn: $share)
                
                Section {
                    Button("Поделиться") {
                        if share == true {
                            shareListToServer()
                        }else{
                            copyListToServer()
                        }
                        self.presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .alert(isPresented: $showInternetErrorAlert) {
                Alert(title: Text("Ошибка"), message: Text("Проверьте подключение к интернету"), dismissButton: .default(Text("OK")))
            }
            .alert(isPresented: $showCommonErrorAlert) {
                Alert(title: Text("Ошибка"), message: Text("Произошли технические неполадки"), dismissButton: .default(Text("OK")))
            }
            .navigationTitle("Поделиться списком")
            .onAppear{
                userId = UUID(uuidString: UserDefaults.standard.string(forKey: "UserId")!)!
                token = UserDefaults.standard.string(forKey: "Token")!
                getAllUserGroups()
                if groupModel.groups.count > 0{
                    selectedGroup = groupModel.groups[0]
                }
            }
        }
        
    }
    
    
    func copyListToServer(){
        do {
            let url = URL(string: "http://localhost:5211/lists/copy_list")!
            let userId = UUID(uuidString: UserDefaults.standard.string(forKey: "UserId") ?? "")
            let token = UserDefaults.standard.string(forKey: "Token")
            
            if forGroup == false{
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                request.addValue("Bearer " + (token ?? ""), forHTTPHeaderField: "Authorization")
                let listModel = ListCopyRequest(listId: listId, newListId: UUID(), userOwnerId: userId!, newUserEmail: newUserEmail)
                let jsonData = try JSONEncoder().encode(listModel)
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
                                showUserNotExistErrorAlert = false
                            } else if httpResponse.statusCode == 404{
                                showUserNotExistErrorAlert = true
                            } else {
                                showCommonErrorAlert = true
                            }
                        }
                    }else{
                        print("Some error")
                    }
                }
                task.resume()
            }else{
                var groupMembers: [GroupMember] = []
                let urlGroupMembers = URL(string: "http://localhost:5211/groups/get_all_group_members?user_id=\(userId!.uuidString.lowercased())&group_id=\(selectedGroup.id.uuidString.lowercased())")!

                var request = URLRequest(url: urlGroupMembers)
                request.httpMethod = "GET"
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                request.addValue("Bearer " + (token!), forHTTPHeaderField: "Authorization")

                let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                    if let error = error {
                        showInternetErrorAlert = true
                        print("Error: \(error)")
                    } else if let data = data {
                        do{
                            if let httpResponse = response as? HTTPURLResponse{
                                if httpResponse.statusCode == 200{
                                    let decoder = JSONDecoder()
                                    groupMembers = try decoder.decode([GroupMember].self, from: data)
                                    for groupMember in groupMembers {
                                        var request = URLRequest(url: url)
                                        request.httpMethod = "POST"
                                        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                                        
                                        request.addValue("Bearer " + (token ?? ""), forHTTPHeaderField: "Authorization")
                                        let listModel = ListCopyRequest(listId: listId, newListId: UUID(), userOwnerId: userId!, newUserEmail: groupMember.email)
                                        let jsonData = try JSONEncoder().encode(listModel)
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
                                                        showUserNotExistErrorAlert = false
                                                    } else if httpResponse.statusCode == 404{
                                                        showUserNotExistErrorAlert = true
                                                    } else {
                                                        showCommonErrorAlert = true
                                                    }
                                                }
                                            }else{
                                                print("Some error")
                                            }
                                        }
                                        task.resume()
                                    }
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
            
            
        } catch {
            print("Some error")
        }
        
        
    }
    
    func shareListToServer(){
        do {
            let url = URL(string: "http://localhost:5211/lists/share_list")!
            let userId = UUID(uuidString: UserDefaults.standard.string(forKey: "UserId") ?? "")
            let token = UserDefaults.standard.string(forKey: "Token")
            if forGroup == false{
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                request.addValue("Bearer " + (token ?? ""), forHTTPHeaderField: "Authorization")
                let listModel = ListShareRequest(listId: listId, userOwnerId: userId!, newUserEmail: newUserEmail)
                let jsonData = try JSONEncoder().encode(listModel)
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
                                showUserNotExistErrorAlert = false
                            } else if httpResponse.statusCode == 404{
                                showUserNotExistErrorAlert = true
                            } else {
                                showCommonErrorAlert = true
                            }
                        }
                    }else{
                        print("Some error")
                    }
                }
                task.resume()
            }else{
                var groupMembers: [GroupMember] = []
                let urlGroupMembers = URL(string: "http://localhost:5211/groups/get_all_group_members?user_id=\(userId!.uuidString.lowercased())&group_id=\(selectedGroup.id.uuidString.lowercased())")!

                var request = URLRequest(url: urlGroupMembers)
                request.httpMethod = "GET"
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                request.addValue("Bearer " + (token!), forHTTPHeaderField: "Authorization")

                let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                    if let error = error {
                        showInternetErrorAlert = true
                        print("Error: \(error)")
                    } else if let data = data {
                        do{
                            if let httpResponse = response as? HTTPURLResponse{
                                if httpResponse.statusCode == 200{
                                    let decoder = JSONDecoder()
                                    groupMembers = try decoder.decode([GroupMember].self, from: data)
                                    for groupMember in groupMembers {
                                        var request = URLRequest(url: url)
                                        request.httpMethod = "POST"
                                        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                                        request.addValue("Bearer " + (token ?? ""), forHTTPHeaderField: "Authorization")
                                        let listModel = ListShareRequest(listId: listId, userOwnerId: userId!, newUserEmail: groupMember.email)
                                        let jsonData = try JSONEncoder().encode(listModel)
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
                                                        showUserNotExistErrorAlert = false
                                                    } else if httpResponse.statusCode == 404{
                                                        showUserNotExistErrorAlert = true
                                                    } else {
                                                        showCommonErrorAlert = true
                                                    }
                                                }
                                            }else{
                                                print("Some error")
                                            }
                                        }
                                        task.resume()
                                    }
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
            
        } catch {
            print("Some error")
        }
        
        
    }
    
    func getAllUserGroups(){
        let url = URL(string: "http://localhost:5211/groups/get_all_user_groups?user_id=\(userId.uuidString.lowercased())")!

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

                            groupModel.groups = try decoder.decode([Group].self, from: data)
                            groupModel.reload()
                            showUserNotExistErrorAlert = false
                            showCommonErrorAlert = false
                            showInternetErrorAlert = false
                        } else if httpResponse.statusCode == 404{
                            print("Такого пользователя не существует")
                            showUserNotExistErrorAlert = true
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
