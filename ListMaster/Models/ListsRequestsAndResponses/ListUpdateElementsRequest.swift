//
//  ListUpdateElementsRequest.swift
//  ListMaster
//
//  Created by Анастасия Доблер on 08.03.2024.
//

import Foundation

public class ListUpdateElementsRequest: Codable {
    public var UserId: UUID
    public var Id: UUID
    public var Elements: String

    init(userId: UUID, id: UUID, elements: String) {
        self.UserId = userId
        self.Id = id
        self.Elements = elements
    }
}
