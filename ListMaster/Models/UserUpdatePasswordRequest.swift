//
//  UserUpdatePasswordRequest.swift
//  ListMaster
//
//  Created by Анастасия Доблер on 25.03.2024.
//

import Foundation

public class UserUpdatePasswordRequest: Codable {
    public var Id: UUID
    public var Password: String

    init(id: UUID, password: String) {
        self.Id = id
        self.Password = password
    }
}
