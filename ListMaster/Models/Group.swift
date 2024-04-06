//
//  Group.swift
//  ListMaster
//
//  Created by Анастасия Доблер on 02.04.2024.
//

import Foundation

public class Group: Codable, Identifiable, ObservableObject, Hashable {
    public var id: UUID
    public var title: String
    public var ownerId: UUID

    init(id: UUID, title: String, owner_id: UUID) {
        self.id = id
        self.title = title
        self.ownerId = owner_id
    }

    public static func == (lhs: Group, rhs: Group) -> Bool {
        return lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
