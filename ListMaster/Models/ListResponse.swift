//
//  ListResponse.swift
//  ListMaster
//
//  Created by Анастасия Доблер on 23.03.2024.
//

import Foundation

struct ListResponse: Codable{
    public var id: UUID
    public var title: String
    public var elements: String
}
