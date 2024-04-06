//
//  ListModel.swift
//  ListMaster
//
//  Created by Анастасия Доблер on 04.03.2024.
//

import Foundation

public class ListAddRequst: Codable {
    public var UserId: UUID
    public var Id: UUID
    public var Title: String
    public var Elements: String
    public var IsShared: Bool
    public var OwnerId: UUID

    init(userId: UUID, id: UUID, title: String, elements: String, is_shared: Bool, owner_id: UUID) {
        self.UserId = userId
        self.Id = id
        self.Title = title
        self.Elements = elements
        self.IsShared = is_shared
        self.OwnerId = owner_id
    }
}
