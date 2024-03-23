//
//  ContentView.swift
//  ListMaster
//
//  Created by Анастасия Доблер on 09.02.2024.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @AppStorage("isUserLoggedIn") private var isUserLoggedIn = false
    
    @State private var showUserNotExistErrorAlert = false
    @State private var showCommonErrorAlert = false
    @State private var showInternetErrorAlert = false
    
    var body: some View {
        NavigationView {
            if isUserLoggedIn {
                MainScreenView()
            } else {
                LoginView()
            }
        }
        .onAppear {
            if UserDefaults.standard.bool(forKey: "isUserLoggedIn") {
                download()
                isUserLoggedIn = true
            }
        }
    }
    
    func download (){
        let userId = UUID(uuidString: UserDefaults.standard.string(forKey: "UserId") ?? "")
        let token = UserDefaults.standard.string(forKey: "Token")
        
        let url = URL(string: "http://localhost:5211/lists/get_all_user_lists?user_id=\(userId!.uuidString.lowercased())")!

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer " + (token ?? ""), forHTTPHeaderField: "Authorization")

        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                showInternetErrorAlert = true
                print("Error: \(error)")
            } else if let data = data {
                do{
                    if let httpResponse = response as? HTTPURLResponse{
                        if httpResponse.statusCode == 200{
                            deleteAllList()
                            deleteAllListElements()
                           
                            let decoder = JSONDecoder()

                            let lists = try decoder.decode([ListResponse].self, from: data)
                            
                            for list in lists {
                                let listEntity = ListEntity(context: viewContext)
                                listEntity.id = list.id
                                listEntity.title = list.title
                                try viewContext.save()
                                
                                if let elementsData = list.elements.data(using: .utf8) {
                                    let elements = try decoder.decode([ListElement].self, from: elementsData)
                                    
                                    for element in elements {
                                        let listElement = ListElementEntity(context: viewContext)
                                        listElement.listId = list.id
                                        listElement.id = element.Id
                                        listElement.title = element.Title
                                        listElement.descriptionText = element.DescriptionText
                                        listElement.deadline = element.Deadline
                                        listElement.createdAt = element.CreatedAt
                                        listElement.count = Int32(element.Count)
                                        listElement.imagePath = element.ImagePath
                                        listElement.isDone = element.IsDone
                                        
                                        try viewContext.save()
                                    }
                                }
                            }
                            
                            showUserNotExistErrorAlert = false
                            showCommonErrorAlert = false
                            showInternetErrorAlert = false
                        } else if httpResponse.statusCode == 404{
                            print("Такого пользователя не существует")
                            showUserNotExistErrorAlert = true
                        } else {
                            print("Bad status code")
                            showCommonErrorAlert = true
                        }
                    }
                }
                catch{
                    print("No data")
                }
                
            }else{
                print("Some error")
            }
        }
        
        task.resume()
    }
    
    func deleteAllList() {
        let fetchRequest: NSFetchRequest<ListEntity> = ListEntity.fetchRequest()
            
        do {
            let lists = try viewContext.fetch(fetchRequest)
            for list in lists {
                viewContext.delete(list)
            }
            try viewContext.save()
        } catch {
            print("Ошибка при удалении: \(error)")
        }
    }
    
    func deleteAllListElements() {
        let fetchRequest: NSFetchRequest<ListElementEntity> = ListElementEntity.fetchRequest()
            
        do {
            let lists = try viewContext.fetch(fetchRequest)
            for list in lists {
                viewContext.delete(list)
            }
            try viewContext.save()
        } catch {
            print("Ошибка при удалении: \(error)")
        }
    }
}
