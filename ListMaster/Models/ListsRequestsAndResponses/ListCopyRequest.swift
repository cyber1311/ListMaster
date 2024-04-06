//
//  ListCopyRequest.swift
//  ListMaster
//
//  Created by Анастасия Доблер on 01.04.2024.
//

import Foundation

public class ListCopyRequest: Codable {
    public var ListId: UUID
    public var NewListId: UUID
    public var UserOwnerId: UUID
    public var NewUserEmail: String

    init(listId: UUID, newListId: UUID, userOwnerId: UUID, newUserEmail: String) {
        self.ListId = listId
        self.NewListId = newListId
        self.UserOwnerId = userOwnerId
        self.NewUserEmail = newUserEmail
    }
}
