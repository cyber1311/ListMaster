//
//  UserInfo.swift
//  ListMaster
//
//  Created by Анастасия Доблер on 06.04.2024.
//

import Foundation

public class UserInfo {
    public var UserId: UUID
    public var UserEmail: String
    public var UserName: String
    public var UserPassword: String
    public var Token: String

    init(){
        if let id = UserDefaults.standard.object(forKey: "UserId") as? String{
            self.UserId = UUID(uuidString: id) ?? UUID()
        } else{
            self.UserId = UUID()
        }
        self.UserEmail = (UserDefaults.standard.object(forKey: "UserEmail") as? String) ?? ""
        self.UserName = (UserDefaults.standard.object(forKey: "UserName") as? String) ?? ""
        self.UserPassword = (UserDefaults.standard.object(forKey: "UserPassword") as? String) ?? ""
        self.Token = (UserDefaults.standard.object(forKey: "Token") as? String) ?? ""
    }
    
    init(user_id: UUID, user_email: String, user_name: String, user_password: String, token: String) {
        self.UserId = user_id
        self.UserEmail = user_email
        self.UserName = user_name
        self.UserPassword = user_password
        self.Token = token
    }
}
