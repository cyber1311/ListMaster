//
//  ListElementTransformer.swift
//  ListMaster
//
//  Created by Анастасия Доблер on 20.02.2024.
//

import Foundation
//import CoreData
//
//
//class ListElementTransformer: ValueTransformer {
//    override func transformedValue(_ value: Any?) -> Any? {
//        guard let elements = value as? [ListElement] else { return nil }
//        
//        do {
//            let data = try JSONEncoder().encode(elements)
//            return data
//        } catch {
//            print("Error encoding ListElement array: \(error)")
//            return nil
//        }
//    }
//
//    override func reverseTransformedValue(_ value: Any?) -> Any? {
//        guard let data = value as? Data else { return nil }
//
//        do {
//            let elements = try JSONDecoder().decode([ListElement].self, from: data)
//            return elements
//        } catch {
//            print("Error decoding ListElement array: \(error)")
//            return nil
//        }
//    }
//}
//
//
//extension ListElementTransformer {
//    /// The name of the transformer. This is the name used to register the transformer using `ValueTransformer.setValueTrandformer(_"forName:)`.
//    static let name = NSValueTransformerName(rawValue: String(describing: ListElementTransformer.self))
//
//    /// Registers the value transformer with `ValueTransformer`.
//    public static func register() {
//        let transformer = ListElementTransformer()
//        ValueTransformer.setValueTransformer(transformer, forName: name)
//    }
//}
