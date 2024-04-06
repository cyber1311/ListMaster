//
//  ListModel.swift
//  ListMaster
//
//  Created by Анастасия Доблер on 31.03.2024.
//

import Foundation

public class ListModel: ObservableObject, Identifiable {
    public var Id: UUID
    @Published var Title: String
    @Published var Elements: [ListElement]
    @Published var IsShared: Bool
    @Published var OwnerId: UUID
    

    init(id: UUID, title: String, elements: [ListElement], is_shared: Bool, owner_id: UUID) {
        self.Id = id
        self.Title = title
        self.Elements = elements
        self.IsShared = is_shared
        self.OwnerId = owner_id
    }
    
    func reload(){
        sort()
        objectWillChange.send()
    }
    
    func sort(){
        Elements.sort(by: {(point1, point2) -> Bool in
            if point1.IsDone == point2.IsDone{
                return point1.CreatedAt < point2.CreatedAt
                
            }
            return point1.IsDone != point2.IsDone && point2.IsDone == true
        })
    }
}

public class ListViewModel: ObservableObject {
    @Published var lists: [ListModel] = []
    func sort(){
        lists.sort(by: {(list1, list2) -> Bool in
            return list1.Title < list2.Title
        })
    }
    func reload(){
        DispatchQueue.main.async{
            self.sort()
            self.objectWillChange.send()
        }
        
    }
}

