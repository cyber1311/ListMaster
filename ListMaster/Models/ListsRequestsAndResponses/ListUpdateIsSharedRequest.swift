//
//  ListUpdateIsSharedRequest.swift
//  ListMaster
//
//  Created by Анастасия Доблер on 01.04.2024.
//

import Foundation

public class ListUpdateIsSharedRequest: Codable {
    public var UserId: UUID
    public var Id: UUID
    public var IsShared: Bool

    init(userId: UUID, id: UUID, isShared: Bool) {
        self.UserId = userId
        self.Id = id
        self.IsShared = isShared
    }
}
