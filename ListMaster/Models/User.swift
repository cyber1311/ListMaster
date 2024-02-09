//
//  User.swift
//  ListMaster
//
//  Created by Анастасия Доблер on 10.02.2024.
//

import Foundation

public class User: Codable {
    public var Id: UUID
    public var Email: String
    public var Name: String
    public var Password: String

    init(id: UUID, email: String, name: String, password: String) {
        self.Id = id
        self.Email = email
        self.Name = name
        self.Password = password
    }
}
