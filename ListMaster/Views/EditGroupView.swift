//
//  EditGroupView.swift
//  ListMaster
//
//  Created by Анастасия Доблер on 02.04.2024.
//

import Foundation
import SwiftUI

struct EditGroupView: View {
    @ObservedObject var groupModel: GroupModel
    @Binding var group: Group
    @State  var userInfo: UserInfo
    @State var newGroupTitle = ""
    @State var newUserEmail = ""
    @State var ownerName = ""
    @State var ownerEmail = ""
    @State private var showErrorAlert = false
    @State private var alertMessage = ""
    @Environment(\.editMode) var editMode
    @ObservedObject var groupMembersModel: GroupMemberModel = GroupMemberModel()
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    var body: some View {
        List {
            if editMode?.wrappedValue == .active{
                Section(header: Text("Изменить название группы")) {
                    HStack {
                        TextField(group.title, text: $newGroupTitle)
                        Button(action: {
                            if newGroupTitle != ""{
                                group.title = newGroupTitle
                                updateGroupTitleForServer()
                                getAllGroupMembers()
                                newGroupTitle = ""
                            }
                            
                        }, label: {
                            Image(systemName: "checkmark.circle.fill")
                        })
                    }
                }
            }
            
            Section(header: Text("Владелец группы:")){
                if let index = groupMembersModel.groupMembers.firstIndex(where: { $0.id == group.ownerId }) {
                    VStack(alignment: .leading){
                        Text(groupMembersModel.groupMembers[index].name).bold()
                        Text(groupMembersModel.groupMembers[index].email)
                    }
                }
                
            }
            
            Section(header: Text("Участники группы:")) {
                if group.ownerId == userInfo.UserId{
                    HStack {
                        TextField("Новый участник", text: $newUserEmail)
                        Button(action: {
                            if newUserEmail != ""{
                                groupAddMemberForServer()
                                newUserEmail = ""
                            }
                            
                        }, label: {
                            Image(systemName: "plus.circle.fill")
                        })
                        .alert(isPresented: $showErrorAlert) {
                            Alert(title: Text("Ошибка"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
                        }
                    }
                }
                if group.ownerId == userInfo.UserId{
                    ForEach($groupMembersModel.groupMembers, id: \.id) { groupMember in
                        if(groupMember.wrappedValue.id != group.ownerId){
                            VStack(alignment: .leading){
                                Text(groupMember.wrappedValue.name).bold()
                                Text(groupMember.wrappedValue.email)
                            }
                        }
                    }
                    .onDelete(perform: removeGroupMember)
                }else{
                    ForEach($groupMembersModel.groupMembers, id: \.id) { groupMember in
                        if(groupMember.wrappedValue.id != group.ownerId){
                            VStack(alignment: .leading){
                                Text(groupMember.wrappedValue.name).bold()
                                Text(groupMember.wrappedValue.email)
                            }
                        }
                    }
                }
                
            }
            if group.ownerId == userInfo.UserId{
                HStack{
                    Spacer()
                    Button(action:{
                        removeGroup()
                        self.presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Удалить группу")
                    }
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    Spacer()
                }
                
            }else{
                HStack{
                    Spacer()
                    Button(action:{
                        removeGroupMemberFromServer(groupMemberId: userInfo.UserId)

                        self.presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Покинуть группу")
                    }
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    Spacer()
                }
                
            }
        }
        .navigationTitle(group.title)
        .onAppear{
            getAllGroupMembers()
            
        }
        .toolbar {
            if group.ownerId == userInfo.UserId{
                ToolbarItem {
                    EditButton()
                }
            }
        }
        .refreshable{
            getAllGroupMembers()
        }
    }
        
    func removeGroupMember(at offsets: IndexSet) {
        for index in offsets {
            let groupMember = groupMembersModel.groupMembers[index]
            let groupMemberId = groupMember.id
            removeGroupMemberFromServer(groupMemberId: groupMemberId)
        }
        groupMembersModel.groupMembers.remove(atOffsets: offsets)
        groupMembersModel.reload()
    }
    
    func removeGroupMemberFromServer(groupMemberId: UUID){
        let url = URL(string: "http://localhost:5211/groups/delete_group_member?user_id=\(userInfo.UserId.uuidString.lowercased())&group_id=\(group.id.uuidString.lowercased())&user_to_delete_id=\(groupMemberId.uuidString.lowercased())")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer " + (userInfo.Token), forHTTPHeaderField: "Authorization")
        
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
    }
    
    func removeGroup(){
        let url = URL(string: "http://localhost:5211/groups/delete_group?user_id=\(userInfo.UserId.uuidString.lowercased())&group_id=\(group.id.uuidString.lowercased())")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer " + (userInfo.Token), forHTTPHeaderField: "Authorization")
        
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
    }
    
    func updateGroupTitleForServer(){
        do{
            
            let groupUpdateTitleRequest = GroupUpdateTitleRequest(id: group.id, title: newGroupTitle, user_id: userInfo.UserId)
            
            let url = URL(string: "http://localhost:5211/groups/update_group_title")!

            var request = URLRequest(url: url)
            request.httpMethod = "PUT"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("Bearer " + (userInfo.Token), forHTTPHeaderField: "Authorization")
            
            let jsonData = try JSONEncoder().encode(groupUpdateTitleRequest)
            request.httpBody = jsonData
            
            let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                if error != nil{
                    DispatchQueue.main.async {
                        showErrorAlert = true
                        alertMessage = "Произошли технические неполадки"
                    }
                }
                else if data != nil {
                    if let httpResponse = response as? HTTPURLResponse{
                        if httpResponse.statusCode == 404{
                            showErrorAlert = true
                            alertMessage = "Такой пользователь не найден"
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
        }catch{
            print("Error")
        }
    }
    
    func groupAddMemberForServer(){
        do {
            let url = URL(string: "http://localhost:5211/groups/add_group_member")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("Bearer " + (userInfo.Token), forHTTPHeaderField: "Authorization")
            let groupMemberAddRequest = GroupMemberAddRequest(group_id: group.id, user_id: userInfo.UserId, user_to_add_email: newUserEmail)
            let jsonData = try JSONEncoder().encode(groupMemberAddRequest)
            request.httpBody = jsonData
            
            let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                if data != nil {
                    if let httpResponse = response as? HTTPURLResponse{
                        if httpResponse.statusCode == 200{
                            getAllGroupMembers()
                        } else if httpResponse.statusCode == 404 {
                            DispatchQueue.main.async {
                                showErrorAlert = true
                                alertMessage = "Пользователь не найден"
                            }
                        }
                        else {
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
        } catch {
            print("Some error")
        }
    }
    
    func getAllGroupMembers(){
        let url = URL(string: "http://localhost:5211/groups/get_all_group_members?user_id=\(userInfo.UserId.uuidString.lowercased())&group_id=\(group.id.uuidString.lowercased())")!

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer " + (userInfo.Token), forHTTPHeaderField: "Authorization")

        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let data = data {
                do{
                    if let httpResponse = response as? HTTPURLResponse{
                        if httpResponse.statusCode == 200{
                            let decoder = JSONDecoder()
                            groupMembersModel.groupMembers = try decoder.decode([GroupMember].self, from: data)
                            groupMembersModel.reload()
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
