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
    @State private var uiImage: UIImage?
    @State private var imagePath: String?
    
    var body: some View {
        if uiImage == nil{
            Image(systemName: "person.circle.fill")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 200, height: 200)
                .foregroundColor(.blue)
        }else{
            Image(uiImage: uiImage!)
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 200)
                .clipShape(Circle())
        }
        Button {
                //
            } label: {
                Label("Редактировать", systemImage: "pencil")
        }
        .contextMenu {
            Button {
                    //
                } label: {
                    Label("Удалить", systemImage: "trash")
                }
                Button {
                    //
                } label: {
                    Label("Выбрать", systemImage: "camera")
                }
        
        }
        .padding()
        
        VStack(alignment: .leading) {
            VStack(alignment: .leading){
                Text("Имя:").bold()
                Text(userName)
            }
            .contextMenu {
                Button(action: {
                    //
                }) {
                    Text("Изменить")
                    Spacer()
                    Image(systemName: "pencil")
                }
            }
            .padding()
            VStack(alignment: .leading){
                Text("Электронная почта:").bold()
                Text(userEmail)
            }
            .contextMenu {
                Button(action: {
                    //
                }) {
                    Text("Изменить")
                    Spacer()
                    Image(systemName: "pencil")
                }
            }
            .padding()
            
            
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
        .navigationTitle("Личный кабинет")
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
