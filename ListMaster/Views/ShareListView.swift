//
//  ShareListView.swift
//  ListMaster
//
//  Created by Анастасия Доблер on 01.04.2024.
//

import Foundation
import SwiftUI

struct ShareListView: View {
    @State private var showErrorAlert = false
    @State private var alertMessage = ""
    @State private var newUserEmail = ""
    @State private var share = false
    @State private var forGroup = false
    @State public var listId: UUID
    @State var userInfo: UserInfo
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
                        Text("Не выбрано")
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
                Section{
                    HStack {
                        Spacer()
                        Button("Поделиться") {
                            if share == true {
                                shareListToServer()
                            }else{
                                copyListToServer()
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
            .navigationTitle("Поделиться списком")
            .onAppear{
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
            if forGroup == false{
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                request.addValue("Bearer " + (userInfo.Token), forHTTPHeaderField: "Authorization")
                let listModel = ListCopyRequest(listId: listId, newListId: UUID(), userOwnerId: userInfo.UserId, newUserEmail: newUserEmail)
                let jsonData = try JSONEncoder().encode(listModel)
                request.httpBody = jsonData

                let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                    if error != nil {
                        DispatchQueue.main.async {
                            showErrorAlert = true
                            alertMessage = "Произошли технические неполадки"
                        }
                    } else if data != nil {
                        if let httpResponse = response as? HTTPURLResponse{
                            if httpResponse.statusCode == 404{
                                DispatchQueue.main.async {
                                    showErrorAlert = true
                                    alertMessage = "Такого пользователя не существует"
                                }
                            } else if httpResponse.statusCode != 200{
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
            }else{
                var groupMembers: [GroupMember] = []
                let urlGroupMembers = URL(string: "http://localhost:5211/groups/get_all_group_members?user_id=\(userInfo.UserId.uuidString.lowercased())&group_id=\(selectedGroup.id.uuidString.lowercased())")!

                var request = URLRequest(url: urlGroupMembers)
                request.httpMethod = "GET"
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                request.addValue("Bearer " + (userInfo.Token), forHTTPHeaderField: "Authorization")

                let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                    if error != nil {
                        DispatchQueue.main.async {
                            showErrorAlert = true
                            alertMessage = "Произошли технические неполадки"
                        }
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
                                        
                                        request.addValue("Bearer " + (userInfo.Token), forHTTPHeaderField: "Authorization")
                                        let listModel = ListCopyRequest(listId: listId, newListId: UUID(), userOwnerId: userInfo.UserId, newUserEmail: groupMember.email)
                                        let jsonData = try JSONEncoder().encode(listModel)
                                        request.httpBody = jsonData

                                        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                                            if error != nil {
                                                DispatchQueue.main.async {
                                                    showErrorAlert = true
                                                    alertMessage = "Произошли технические неполадки"
                                                }
                                            } else if data != nil {
                                                if let httpResponse = response as? HTTPURLResponse{
                                                    if httpResponse.statusCode == 404{
                                                        DispatchQueue.main.async {
                                                            showErrorAlert = true
                                                            alertMessage = "Такого пользователя не существует"
                                                        }
                                                    } else if httpResponse.statusCode != 200 {
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
                                    self.presentationMode.wrappedValue.dismiss()
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
            
            
        } catch {
            DispatchQueue.main.async {
                showErrorAlert = true
                alertMessage = "Произошли технические неполадки"
            }
        }
        
        
    }
    
    func shareListToServer(){
        do {
            let url = URL(string: "http://localhost:5211/lists/share_list")!
            if forGroup == false{
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                request.addValue("Bearer " + (userInfo.Token), forHTTPHeaderField: "Authorization")
                let listModel = ListShareRequest(listId: listId, userOwnerId: userInfo.UserId, newUserEmail: newUserEmail)
                let jsonData = try JSONEncoder().encode(listModel)
                request.httpBody = jsonData

                let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                    if error != nil {
                        DispatchQueue.main.async {
                            showErrorAlert = true
                            alertMessage = "Произошли технические неполадки"
                        }
                    } else if data != nil {
                        if let httpResponse = response as? HTTPURLResponse{
                            if httpResponse.statusCode == 404{
                                DispatchQueue.main.async {
                                    showErrorAlert = true
                                    alertMessage = "Такого пользователя не существует"
                                }
                            }else if httpResponse.statusCode != 200{
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
            }else{
                var groupMembers: [GroupMember] = []
                let urlGroupMembers = URL(string: "http://localhost:5211/groups/get_all_group_members?user_id=\(userInfo.UserId.uuidString.lowercased())&group_id=\(selectedGroup.id.uuidString.lowercased())")!

                var request = URLRequest(url: urlGroupMembers)
                request.httpMethod = "GET"
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                request.addValue("Bearer " + (userInfo.Token), forHTTPHeaderField: "Authorization")

                let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                    if error != nil {
                        DispatchQueue.main.async {
                            showErrorAlert = true
                            alertMessage = "Произошли технические неполадки"
                        }
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
                                        request.addValue("Bearer " + (userInfo.Token), forHTTPHeaderField: "Authorization")
                                        let listModel = ListShareRequest(listId: listId, userOwnerId: userInfo.UserId, newUserEmail: groupMember.email)
                                        let jsonData = try JSONEncoder().encode(listModel)
                                        request.httpBody = jsonData
                                        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                                            if error != nil {
                                                DispatchQueue.main.async {
                                                    showErrorAlert = true
                                                    alertMessage = "Произошли технические неполадки"
                                                }
                                            } else if data != nil {
                                                if let httpResponse = response as? HTTPURLResponse{
                                                    if httpResponse.statusCode == 404{
                                                        DispatchQueue.main.async {
                                                            showErrorAlert = true
                                                            alertMessage = "Такого пользователя не существует"
                                                        }
                                                    } else if httpResponse.statusCode != 200{
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
                                    self.presentationMode.wrappedValue.dismiss()
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
            
        } catch {
            DispatchQueue.main.async {
                showErrorAlert = true
                alertMessage = "Произошли технические неполадки"
            }
        }
        
        
    }
    
    func getAllUserGroups(){
        let url = URL(string: "http://localhost:5211/groups/get_all_user_groups?user_id=\(userInfo.UserId.uuidString.lowercased())")!

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer " + (userInfo.Token), forHTTPHeaderField: "Authorization")

        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if error != nil {
                DispatchQueue.main.async {
                    showErrorAlert = true
                    alertMessage = "Произошли технические неполадки"
                }
            } else if let data = data {
                do{
                    if let httpResponse = response as? HTTPURLResponse{
                        if httpResponse.statusCode == 200{
                            let decoder = JSONDecoder()

                            groupModel.groups = try decoder.decode([Group].self, from: data)
                            groupModel.reload()
                        } else if httpResponse.statusCode == 404{
                            DispatchQueue.main.async {
                                showErrorAlert = true
                                alertMessage = "Такого пользователя не существует"
                            }
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
