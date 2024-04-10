//
//  ProfileView.swift
//  ListMaster
//
//  Created by Анастасия Доблер on 13.02.2024.
//

import SwiftUI

struct ProfileView: View {
    @State var userInfo: UserInfo
    @State private var conditionIsMet = false
    @ObservedObject var groupModel: GroupModel = GroupModel()
    @State private var showErrorAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        List{
            Section{
                HStack(alignment: .center){
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width:50, height: 50)
                        .foregroundColor(.blue)
                    VStack(alignment: .leading, content: {
                        Text(userInfo.UserName).bold()
                        Text(userInfo.UserEmail)
                    })
                }
            }
            
            Section(header: Text("Ваши группы:")){
                ForEach($groupModel.groups) { group in
                    NavigationLink(destination: EditGroupView(groupModel: groupModel, group: group, userInfo: userInfo)) {
                        Text(group.wrappedValue.title)
                    }
                }
                NavigationLink(destination: AddGroupView(groupModel: groupModel, userInfo: userInfo)) {
                    Text("Добавить новую группу").foregroundColor(.blue)
                }
            }
            
            Section(header: Text("Настройки")){
                NavigationLink(destination: ChangeNameView(userInfo: userInfo)) {
                    Text("Изменить имя").foregroundColor(.blue)
                }
                NavigationLink(destination: ChangeEmailView(userInfo: userInfo)) {
                    Text("Изменить электронную почту").foregroundColor(.blue)
                }
                NavigationLink(destination: ChangePasswordView(userInfo: userInfo)) {
                    Text("Изменить пароль").foregroundColor(.blue)
                }
                NavigationLink(destination: DeleteUserView(userInfo: userInfo)) {
                    Text("Удалить аккаунт").foregroundColor(.red)
                }
            }

            HStack{
                Spacer()
                Button(action:{
                    UserDefaults.standard.removeObject(forKey: "isUserLoggedIn")
                    UserDefaults.standard.removeObject(forKey: "UserId")
                    UserDefaults.standard.removeObject(forKey: "UserName")
                    UserDefaults.standard.removeObject(forKey: "UserPassword")
                    UserDefaults.standard.removeObject(forKey: "UserEmail")
                    UserDefaults.standard.removeObject(forKey: "Token")
                    UserDefaults.standard.removeObject(forKey: "TokenExpiresAt")

                    conditionIsMet = true
                }) {
                    Text("Выйти")
                }
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(10)
                Spacer()
            }
        }
        .navigationTitle("Профиль")
        .onAppear{
            getAllUserGroups()
        }
        .fullScreenCover(isPresented: $conditionIsMet) {
            ContentView()
        }
        .refreshable{
            getAllUserGroups()
        }
        .alert(isPresented: $showErrorAlert) {
            Alert(title: Text("Ошибка"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
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
        groupModel.reload()
    }
    
}
