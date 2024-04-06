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
    @State private var userId: UUID = UUID()
    @State private var token: String = ""
    @State var newGroupTitle = ""
    @State var newUserEmail = ""
    @State var ownerName = ""
    @State var ownerEmail = ""
    @State private var showInternetErrorAlert = false
    @State private var showCommonErrorAlert = false
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
                if group.ownerId == userId{
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
                        .alert(isPresented: $showInternetErrorAlert) {
                            Alert(title: Text("Ошибка"), message: Text("Проверьте подключение к интернету"), dismissButton: .default(Text("OK")))
                        }
                        .alert(isPresented: $showCommonErrorAlert) {
                            Alert(title: Text("Ошибка"), message: Text("Произошли технические неполадки"), dismissButton: .default(Text("OK")))
                        }
                    }
                }
                if group.ownerId == userId{
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
            if group.ownerId == userId{
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
                        removeGroupMemberFromServer(groupMemberId: userId)

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
            userId = UUID(uuidString: UserDefaults.standard.string(forKey: "UserId")!)!
            token = UserDefaults.standard.string(forKey: "Token")!
            getAllGroupMembers()
        }
        .toolbar {
            if group.ownerId == userId{
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
    }
    
    func removeGroupMemberFromServer(groupMemberId: UUID){
        let url = URL(string: "http://localhost:5211/groups/delete_group_member?user_id=\(userId.uuidString.lowercased())&group_id=\(group.id.uuidString.lowercased())&user_to_delete_id=\(groupMemberId.uuidString.lowercased())")!
        
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
    
    func removeGroup(){
        let url = URL(string: "http://localhost:5211/groups/delete_group?user_id=\(userId.uuidString.lowercased())&group_id=\(group.id.uuidString.lowercased())")!
        
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
    
    func updateGroupTitleForServer(){
        do{
            
            let groupUpdateTitleRequest = GroupUpdateTitleRequest(id: group.id, title: newGroupTitle, user_id: userId)
            
            let url = URL(string: "http://localhost:5211/groups/update_group_title")!

            var request = URLRequest(url: url)
            request.httpMethod = "PUT"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("Bearer " + (token), forHTTPHeaderField: "Authorization")
            
            let jsonData = try JSONEncoder().encode(groupUpdateTitleRequest)
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
    
    func groupAddMemberForServer(){
        do {
            let url = URL(string: "http://localhost:5211/groups/add_group_member")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("Bearer " + (token), forHTTPHeaderField: "Authorization")
            let groupMemberAddRequest = GroupMemberAddRequest(group_id: group.id, user_id: userId, user_to_add_email: newUserEmail)
            let jsonData = try JSONEncoder().encode(groupMemberAddRequest)
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
                            getAllGroupMembers()
                        } else {
                            print("Some error")
                            showCommonErrorAlert = true
                        }
                    }
                    
                }else{
                    showCommonErrorAlert = true
                    print("Some error")
                }
            }
            
            task.resume()
        } catch {
            print("Some error")
        }
    }
    
    func getAllGroupMembers(){
        let url = URL(string: "http://localhost:5211/groups/get_all_group_members?user_id=\(userId.uuidString.lowercased())&group_id=\(group.id.uuidString.lowercased())")!

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
                            groupMembersModel.groupMembers = try decoder.decode([GroupMember].self, from: data)
                            groupMembersModel.reload()
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
