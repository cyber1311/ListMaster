//
//  LoginResponse.swift
//  ListMaster
//
//  Created by Анастасия Доблер on 13.02.2024.
//

import Foundation


struct LoginResponse: Codable {
    public var id: UUID
    public var name: String
    let token: String
    let expiresAt: String
}
