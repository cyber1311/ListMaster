//
//  LoginRequest.swift
//  ListMaster
//
//  Created by Анастасия Доблер on 13.02.2024.
//

import Foundation


public class LoginRequest: Codable {
    public var Email: String
    public var Password: String

    init(email: String, password: String) {
        self.Email = email
        self.Password = password
    }
}
