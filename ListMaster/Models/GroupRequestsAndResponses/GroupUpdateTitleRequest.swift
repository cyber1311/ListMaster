//
//  GroupUpdateTitleRequest.swift
//  ListMaster
//
//  Created by Анастасия Доблер on 02.04.2024.
//

import Foundation

public class GroupUpdateTitleRequest: Codable {
    public var Id: UUID
    public var Title: String
    public var UserId: UUID

    init(id: UUID, title: String, user_id: UUID) {
        self.Id = id
        self.Title = title
        self.UserId = user_id
    }
}
