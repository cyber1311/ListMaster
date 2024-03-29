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
    
    var body: some View {
        Image(systemName: "person.circle.fill")
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: 200, height: 200)
            .foregroundColor(.blue)
        .padding()
        
        VStack{
            HStack{
                VStack(alignment: .leading){
                    Text("Имя:").bold()
                    Text(userName)
                }
                Spacer()
                NavigationLink(destination: ChangeNameView()) {
                    Image(systemName: "pencil")
                    
                }
            }
            .padding()
            HStack{
                VStack(alignment: .leading){
                    Text("Электронная почта:").bold()
                    Text(userEmail)
                }
                Spacer()
                NavigationLink(destination: ChangeEmailView()) {
                    Image(systemName: "pencil")
                }
            }
            .padding()
            NavigationLink(destination: ChangePasswordView()) {
                HStack {
                    Text("Изменить пароль")
                    Image(systemName: "pencil")
                }
            }
            
        }.fullScreenCover(isPresented: $conditionIsMet) {
            LoginView()
        }
        VStack(alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/, content: {
            Button(action:{
                UserDefaults.standard.removeObject(forKey: "isUserLoggedIn")
                UserDefaults.standard.removeObject(forKey: "UserId")
                UserDefaults.standard.removeObject(forKey: "UserName")
                UserDefaults.standard.removeObject(forKey: "UserPassword")
                UserDefaults.standard.removeObject(forKey: "UserEmail")
                UserDefaults.standard.removeObject(forKey: "Token")
                UserDefaults.standard.removeObject(forKey: "TokenExpiresAt")
            }) {
                Text("Выйти")
            }
            .padding()
            .background(Color.red)
            .foregroundColor(.white)
            .cornerRadius(10)
        })
        
        .padding()
        .navigationTitle("Профиль")
        .onAppear{
            if let name = UserDefaults.standard.object(forKey: "UserName") as? String {
                userName = name
            }
            if let email = UserDefaults.standard.object(forKey: "UserEmail") as? String {
                userEmail = email
            }
        }
    }
}
