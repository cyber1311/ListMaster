//
//  UserUpdateEmailRequest.swift
//  ListMaster
//
//  Created by Анастасия Доблер on 25.03.2024.
//

import Foundation

public class UserUpdateEmailRequest: Codable {
    public var Id: UUID
    public var Email: String

    init(id: UUID, email: String) {
        self.Id = id
        self.Email = email
    }
}
