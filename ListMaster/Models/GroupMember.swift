//
//  GroupMember.swift
//  ListMaster
//
//  Created by Анастасия Доблер on 02.04.2024.
//

import Foundation

public class GroupMember: Codable {
    public var id: UUID
    public var email: String
    public var name: String

    init(id: UUID, email: String, name: String) {
        self.id = id
        self.email = email
        self.name = name
    }
}

public class GroupMemberModel: ObservableObject{
    @Published var groupMembers: [GroupMember] = []
    
    func sort(){
        groupMembers.sort(by: {(member1, member2) -> Bool in
            return member1.name < member2.name
        })
    }
    
    func reload(){
        DispatchQueue.main.async{
            self.sort()
            self.objectWillChange.send()
        }
        
    }
}

public class UserModel: ObservableObject{
    @Published var users: [GroupMember] = []
    
    func sort(){
        users.sort(by: {(member1, member2) -> Bool in
            return member1.name < member2.name
        })
    }
    
    func reload(){
        DispatchQueue.main.async{
            self.sort()
            self.objectWillChange.send()
        }
        
    }
}
