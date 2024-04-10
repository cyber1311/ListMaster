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
    @State var userInfo: UserInfo
    @State var groupTitle = ""
    @State private var showErrorAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        Form {
            Section(header: Text("Создание новой группы")) {
                TextField("Название группы", text: $groupTitle)
            }
            HStack(alignment: .center) {
                Spacer()
                Button(action: {
                    if groupTitle == ""{
                        groupTitle = "Новая группа"
                    }
                    let groupId = UUID()
                    groupModel.groups.append(Group(id: groupId, title: groupTitle, owner_id: userInfo.UserId))
                    groupModel.reload()
                    addGroupToServer(groupId: groupId)
                    self.groupTitle = ""
                    self.presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Сохранить")
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                Spacer()
            }
        }
        .navigationTitle("Профиль")
        .onAppear{
            groupModel.reload()
        }
    }
    
    func addGroupToServer(groupId: UUID){
        do {
            let url = URL(string: "http://localhost:5211/groups/add_group")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("Bearer " + (userInfo.Token), forHTTPHeaderField: "Authorization")
            let group = Group(id: groupId, title: groupTitle, owner_id: userInfo.UserId)
            let jsonData = try JSONEncoder().encode(group)
            request.httpBody = jsonData
            
            let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                if error != nil {
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
        } catch {
            DispatchQueue.main.async {
                showErrorAlert = true
                alertMessage = "Произошли технические неполадки"
            }
        }
    }
}
