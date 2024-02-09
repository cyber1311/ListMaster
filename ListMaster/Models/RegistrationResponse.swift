//
//  RegistrationResponse.swift
//  ListMaster
//
//  Created by Анастасия Доблер on 11.02.2024.
//

import Foundation

struct RegistrationResponse: Codable {
    let token: String
    let expiresAt: String
}
