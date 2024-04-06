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
    public var TokenExpiresAt: Date

    init(user_id: UUID, user_email: String, user_name: String, user_password: String, token: String, token_expires_at: Date) {
        self.UserId = user_id
        self.UserEmail = user_email
        self.UserName = user_name
        self.UserPassword = user_password
        self.Token = token
        self.TokenExpiresAt = token_expires_at
    }
}
