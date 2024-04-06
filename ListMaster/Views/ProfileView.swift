//
//  ProfileView.swift
//  ListMaster
//
//  Created by Анастасия Доблер on 13.02.2024.
//

import SwiftUI

struct ProfileView: View {
    @State private var userName = ""
    @State private var userEmail = ""
    @State private var userPassword = ""
    @State private var conditionIsMet = false
    @State private var userId: UUID = UUID()
    @State private var token: String = ""
    @ObservedObject var groupModel: GroupModel = GroupModel()
    @State private var showInternetErrorAlert = false
    @State private var showCommonErrorAlert = false
    @State private var showUserNotExistErrorAlert = false
    
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
                        Text(userName).bold()
                        Text(userEmail)
                    })
                }
            }
            
            Section(header: Text("Ваши группы:")){
                ForEach($groupModel.groups) { group in
                    NavigationLink(destination: EditGroupView(groupModel: groupModel, group: group)) {
                        Text(group.wrappedValue.title)
                    }
                }
                NavigationLink(destination: AddGroupView(groupModel: groupModel)) {
                    Text("Добавить новую группу").foregroundColor(.blue)
                }
            }
            
            Section(header: Text("Настройки")){
                NavigationLink(destination: ChangeNameView()) {
                    Text("Изменить имя").foregroundColor(.blue)
                }
                NavigationLink(destination: ChangeEmailView()) {
                    Text("Изменить электронную почту").foregroundColor(.blue)
                }
                NavigationLink(destination: ChangePasswordView()) {
                    Text("Изменить пароль").foregroundColor(.blue)
                }
                NavigationLink(destination: DeleteUserView()) {
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
            if let name = UserDefaults.standard.object(forKey: "UserName") as? String {
                userName = name
            }
            if let email = UserDefaults.standard.object(forKey: "UserEmail") as? String {
                userEmail = email
            }
            userId = UUID(uuidString: UserDefaults.standard.string(forKey: "UserId")!)!
            token = UserDefaults.standard.string(forKey: "Token")!
            getAllUserGroups()
        }
        .fullScreenCover(isPresented: $conditionIsMet) {
            ContentView()
        }
        .refreshable{
            getAllUserGroups()
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
