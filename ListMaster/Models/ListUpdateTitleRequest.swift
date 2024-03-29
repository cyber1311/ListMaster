//
//  ListUpdateTitleRequest.swift
//  ListMaster
//
//  Created by Анастасия Доблер on 29.03.2024.
//

import Foundation

public class ListUpdateTitleRequest: Codable {
    public var UserId: UUID
    public var Id: UUID
    public var Title: String

    init(userId: UUID, id: UUID, title: String) {
        self.UserId = userId
        self.Id = id
        self.Title = title
    }
}
