//
//  UserUpdateNameRequest.swift
//  ListMaster
//
//  Created by Анастасия Доблер on 25.03.2024.
//

import Foundation

public class UserUpdateNameRequest: Codable {
    public var Id: UUID
    public var Name: String

    init(id: UUID, name: String) {
        self.Id = id
        self.Name = name
    }
}
