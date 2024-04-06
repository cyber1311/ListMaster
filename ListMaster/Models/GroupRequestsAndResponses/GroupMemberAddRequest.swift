//
//  GroupMemberAddRequest.swift
//  ListMaster
//
//  Created by Анастасия Доблер on 02.04.2024.
//

import Foundation

public class GroupMemberAddRequest: Codable {
    public var GroupId: UUID
    public var UserId: UUID
    public var UserToAddEmail: String
    
    init(group_id: UUID, user_id: UUID, user_to_add_email: String) {
        self.GroupId = group_id
        self.UserId = user_id
        self.UserToAddEmail = user_to_add_email
    }
}
