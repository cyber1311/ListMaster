//
//  AddGroupView.swift
//  ListMaster
//
//  Created by Анастасия Доблер on 02.04.2024.
//

import Foundation
import SwiftUI

struct AddGroupView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @ObservedObject public var groupModel: GroupModel
    @State private var userId: UUID = UUID()
    @State private var token: String = ""
    @State var groupTitle = ""
    @State private var showInternetErrorAlert = false
    @State private var showCommonErrorAlert = false
    
    var body: some View {
        Form {
            Section(header: Text("Создание новой группы")) {
                TextField("Название группы", text: $groupTitle)
            }
            Section {
                Button(action: {
                    if groupTitle == ""{
                        groupTitle = "Новая группа"
                    }
                    let groupId = UUID()
                    groupModel.groups.append(Group(id: groupId, title: groupTitle, owner_id: userId))
                    addGroupToServer(groupId: groupId)
                    self.groupTitle = ""
                    groupModel.reload()
                    self.presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Сохранить")
                }
            }
        }
        .navigationTitle("Профиль")
        .onAppear{
            userId = UUID(uuidString: UserDefaults.standard.string(forKey: "UserId")!)!
            token = UserDefaults.standard.string(forKey: "Token")!
        }
    }
    
    func addGroupToServer(groupId: UUID){
        do {
            let url = URL(string: "http://localhost:5211/groups/add_group")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("Bearer " + (token), forHTTPHeaderField: "Authorization")
            let group = Group(id: groupId, title: groupTitle, owner_id: userId)
            let jsonData = try JSONEncoder().encode(group)
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
                    showCommonErrorAlert = true
                    print("Some error")
                }
            }
            
            task.resume()
            groupModel.reload()
        } catch {
            print("Some error")
        }
    }
}
