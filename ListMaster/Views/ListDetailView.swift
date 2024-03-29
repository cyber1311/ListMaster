//
//  ListDetailView.swift
//  ListMaster
//
//  Created by Анастасия Доблер on 15.03.2024.
//

import Foundation
import SwiftUI
import CoreData


struct ListDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var newListElement = ""
    @State private var newListTitle = ""
        
    @State private var showInternetErrorAlert = false
    @State private var showCommonErrorAlert = false
    
    @State private var hideDone = false
        
    @State var listId: UUID
    @State var listTitle: String

    @ObservedObject var viewModel: ListDetailViewModel = ListDetailViewModel()

    @Environment(\.editMode) var editMode
    
    var body: some View {
        List {
            if editMode?.wrappedValue == .active{
                Toggle("Скрыть выполненное", isOn: $hideDone)
                Section(header: Text("Изменить название списка")) {
                    HStack {
                        TextField(listTitle, text: $newListTitle)
                        Button(action: {
                            if newListTitle != ""{
                                listTitle = newListTitle
                                updateListTitle(newTitle: listTitle)
                                updateListTitleForServer()
                                newListTitle = ""
                                loadListElements()
                            }
                            
                        }, label: {
                            Image(systemName: "checkmark.circle.fill")
                        })
                    }
                }
            }
            
            Section(header: Text("Новый пункт")) {
                HStack {
                    TextField("Название", text: $newListElement)
                    Button(action: {
                        if newListElement != ""{
                            let listElement = ListElementEntity(context: viewContext)
                            listElement.listId = listId
                            listElement.id = UUID()
                            listElement.title = self.newListElement
                            listElement.createdAt = Date()
                            do {
                                try viewContext.save()
                                loadListElements()
                                updateForServer()
                            } catch {
                                print(error)
                            }
                            self.newListElement = ""
                            
                        }
                        
                    }, label: {
                        Image(systemName: "plus.circle.fill")
                    })
                    .alert(isPresented: $showInternetErrorAlert) {
                        Alert(title: Text("Ошибка"), message: Text("Проверьте подключение к интернету"), dismissButton: .default(Text("OK")))
                    }
                    .alert(isPresented: $showCommonErrorAlert) {
                        Alert(title: Text("Ошибка"), message: Text("Произошли технические неполадки"), dismissButton: .default(Text("OK")))
                    }
                }
            }
            Section(header: Text("")) {
                ForEach(viewModel.listElements) { element in
                    if hideDone == false || (hideDone == true && element.isDone == false){
                        HStack{
                            if let imagePath = element.imagePath, let uiImage = loadImageFromPath(imagePath: imagePath) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .frame(width: 50, height: 50)
                                    .clipShape(Circle())
                            } else {
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 50, height: 50)
                            }
                            NavigationLink(destination: PointView(listElement: element, viewModel: viewModel, listTitle: $listTitle)) {
                                if element.isDone == true{
                                    Text(element.title!)
                                        .foregroundColor(.green)
                                        .strikethrough()
                                }else if element.deadline != nil && element.deadline!.compare(Date()) == .orderedAscending{
                                    Text(element.title!)
                                        .foregroundColor(.red)
                                }else{
                                    Text(element.title!)
                                }
                            }
                        }
                    }
                }
                .onDelete(perform: removeListElement)
            }
        }
        
        .onAppear {
            loadListElements()
            self.listId = listId
            self.listTitle = listTitle

        }
        .toolbar {
            ToolbarItem {
                EditButton()
            }
                        
        }
        .navigationTitle(listTitle)
        
        
    }
    
    func loadImageFromPath(imagePath: String) -> UIImage? {
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: imagePath) {
                if let imageData = fileManager.contents(atPath: imagePath) {
                    return UIImage(data: imageData)
                }
            }
            return nil
    }
    

    func removeListElement(at offsets: IndexSet) {
        for index in offsets {
            let man = viewModel.listElements[index]
            viewContext.delete(man)
            do {
                try self.viewContext.save()
            } catch {
                print(error)
            }
        }
        loadListElements()
        updateForServer()
    }
    
    func updateForServer(){
        do {
            var elements = [ListElement]()
            for element in viewModel.listElements {
                elements.append(ListElement(id: element.id!, title: element.title!, descriptionText: element.descriptionText, imagePath: element.imagePath, deadline: element.deadline, count: Int(element.count), isDone: element.isDone, createdAt: element.createdAt!))
            }
            let jsonElements = try JSONEncoder().encode(elements)
            let stringElements = String(data: jsonElements, encoding: .utf8)
            let userId = UUID(uuidString: UserDefaults.standard.string(forKey: "UserId") ?? "")
            
            
            let listUpdateElementsRequest = ListUpdateElementsRequest(userId: userId!, id: listId, elements: stringElements!)
            
            let token = UserDefaults.standard.string(forKey: "Token")
            
            let url = URL(string: "http://localhost:5211/lists/update_list_elements")!

            var request = URLRequest(url: url)
            request.httpMethod = "PUT"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("Bearer " + (token ?? ""), forHTTPHeaderField: "Authorization")
            
            let jsonData = try JSONEncoder().encode(listUpdateElementsRequest)
            request.httpBody = jsonData
            
            let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                if let error = error {
                    showInternetErrorAlert = true
                    print("Error: \(error)")
                } else if data != nil {
                    if let httpResponse = response as? HTTPURLResponse{
                        if httpResponse.statusCode == 200{
                            showCommonErrorAlert = false
                            showInternetErrorAlert = false
                        } else {
                            print("Some error")
                            showCommonErrorAlert = true
                        }
                    }
                    
                }else{
                    print("Some error")
                }
            }
            
            task.resume()
            
        } catch {
            print(error)
        }
        
    }
    
    func updateListTitleForServer(){
        do{
            let userId = UUID(uuidString: UserDefaults.standard.string(forKey: "UserId") ?? "")
            
            let listUpdateTitleRequest = ListUpdateTitleRequest(userId: userId!, id: listId, title: listTitle)
            
            let token = UserDefaults.standard.string(forKey: "Token")
            
            let url = URL(string: "http://localhost:5211/lists/update_list_title")!

            var request = URLRequest(url: url)
            request.httpMethod = "PUT"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("Bearer " + (token ?? ""), forHTTPHeaderField: "Authorization")
            
            let jsonData = try JSONEncoder().encode(listUpdateTitleRequest)
            request.httpBody = jsonData
            
            let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                if let error = error {
                    showInternetErrorAlert = true
                    print("Error: \(error)")
                } else if data != nil {
                    if let httpResponse = response as? HTTPURLResponse{
                        if httpResponse.statusCode == 200{
                            showCommonErrorAlert = false
                            showInternetErrorAlert = false
                        } else {
                            print("Some error")
                            showCommonErrorAlert = true
                        }
                    }
                    
                }else{
                    print("Some error")
                }
            }
            
            task.resume()
        }catch{
            print("Error")
        }
    }
    
    func loadListElements() {
        let fetchRequest: NSFetchRequest<ListElementEntity> = ListElementEntity.fetchRequest()

        let sortByIsDone = NSSortDescriptor(keyPath: \ListElementEntity.isDone, ascending: true)
        let sortByCreatedAt = NSSortDescriptor(keyPath: \ListElementEntity.createdAt, ascending: false)
        
        fetchRequest.sortDescriptors = [sortByIsDone, sortByCreatedAt]
        
        fetchRequest.predicate = NSPredicate(format: "listId == %@", listId.uuidString)
        do {
            self.viewModel.listElements = try viewContext.fetch(fetchRequest)
        } catch {
            print("Error fetching list elements: \(error)")
        }
    }
    
    func updateListTitle(newTitle: String) {
        let fetchRequest: NSFetchRequest<ListEntity> = ListEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", listId.uuidString)

        do {
            let fetchedResults = try viewContext.fetch(fetchRequest)
            
            if let listEntity = fetchedResults.first {
                listEntity.title = newTitle
                try viewContext.save()
            }
        } catch {
            print("Fetch failed: \(error)")
        }
    }
    
    
}


class ListDetailViewModel: ObservableObject {
    @Published var listElements: [ListElementEntity] = []
}
