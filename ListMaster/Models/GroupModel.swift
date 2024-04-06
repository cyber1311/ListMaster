//
//  GroupModel.swift
//  ListMaster
//
//  Created by Анастасия Доблер on 02.04.2024.
//

import Foundation

public class GroupModel: ObservableObject{
    @Published var groups: [Group] = []
    
    func sort(){
        groups.sort(by: {(group1, group2) -> Bool in
            return group1.title < group2.title
        })
    }
    
    func reload(){
        DispatchQueue.main.async{
            self.sort()
            self.objectWillChange.send()
        }
        
    }
}
