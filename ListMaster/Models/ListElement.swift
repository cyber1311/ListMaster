//
//  ListElement.swift
//  ListMaster
//
//  Created by Анастасия Доблер on 08.03.2024.
//

import Foundation

public class ListElement: Codable {
    public var Title: String
    public var DescriptionText: String?
    public var ImagePath: String?
    public var Deadline: Date?
    public var Count: Int
    public var IsDone: Bool
    

    init(title: String, descriptionText: String?, imagePath: String?, deadline: Date?, count: Int, isDone: Bool) {
        self.Title = title
        self.DescriptionText = descriptionText
        self.ImagePath = imagePath
        self.Deadline = deadline
        self.Count = count
        self.IsDone = isDone
    }
}
