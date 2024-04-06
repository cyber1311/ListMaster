//
//  ListDuplicateRequest.swift
//  ListMaster
//
//  Created by Анастасия Доблер on 01.04.2024.
//

import Foundation

public class ListDuplicateRequest: Codable {
    public var ListId: UUID
    public var NewListId: UUID
    public var UserId: UUID

    init(listId: UUID, newListId: UUID, userId: UUID) {
        self.ListId = listId
        self.NewListId = newListId
        self.UserId = userId
    }
}
