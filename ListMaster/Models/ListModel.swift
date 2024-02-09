//
//  ListModel.swift
//  ListMaster
//
//  Created by Анастасия Доблер on 04.03.2024.
//

import Foundation

public class ListModel: Codable {
    public var UserId: UUID
    public var Id: UUID
    public var Title: String
    public var Elements: String

    init(userId: UUID, id: UUID, title: String, elements: String) {
        self.UserId = userId
        self.Id = id
        self.Title = title
        self.Elements = elements
    }
}
