//
//  ListShareRequest.swift
//  ListMaster
//
//  Created by Анастасия Доблер on 01.04.2024.
//

import Foundation

public class ListShareRequest: Codable {
    public var ListId: UUID
    public var UserOwnerId: UUID
    public var NewUserEmail: String

    init(listId: UUID, userOwnerId: UUID, newUserEmail: String) {
        self.ListId = listId
        self.UserOwnerId = userOwnerId
        self.NewUserEmail = newUserEmail
    }
}
