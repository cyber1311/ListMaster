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
        
    @State private var showInternetErrorAlert = false
    @State private var showCommonErrorAlert = false
        
    @State var listId: UUID
    @State var listTitle: String

    @ObservedObject var viewModel: ListDetailViewModel = ListDetailViewModel()

   
    
    var body: some View {
        List {
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
                }
            }
            Section(header: Text("")) {
                
                ForEach($viewModel.listElements) { element in
                    HStack{
                        if let imagePath = element.wrappedValue.imagePath, let uiImage = loadImageFromPath(imagePath: imagePath) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 50, height: 50)
                        }
                        NavigationLink(destination: PointView(listElement: element, listElements: $viewModel.listElements, listTitle: $listTitle)) {
                            if element.wrappedValue.isDone == true{
                                Text(element.wrappedValue.title!)
                                    .foregroundColor(.green)
                                    .strikethrough()
                            }else{
                                Text(element.wrappedValue.title!)
                            }
                        }
                    }
                }
                .onDelete(perform: removeListElement)
            }
            .alert(isPresented: $showInternetErrorAlert) {
                Alert(title: Text("Ошибка"), message: Text("Проверьте подключение к интернету"), dismissButton: .default(Text("OK")))
            }
            .alert(isPresented: $showCommonErrorAlert) {
                Alert(title: Text("Ошибка"), message: Text("Произошли технические неполадки"), dismissButton: .default(Text("OK")))
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
                        
        }.navigationTitle(listTitle)
        
        
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
    
    func loadListElements() {
        let fetchRequest: NSFetchRequest<ListElementEntity> = ListElementEntity.fetchRequest()

        let sortByIsDone = NSSortDescriptor(keyPath: \ListElementEntity.isDone, ascending: true)
        let sortByCreatedAt = NSSortDescriptor(keyPath: \ListElementEntity.createdAt, ascending: false)
        
        fetchRequest.sortDescriptors = [sortByIsDone, sortByCreatedAt]
        
        fetchRequest.predicate = NSPredicate(format: "listId == %@", listId.uuidString)
        do {
            viewModel.listElements = try viewContext.fetch(fetchRequest)
        } catch {
            print("Error fetching list elements: \(error)")
        }
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
    
    
}


class ListDetailViewModel: ObservableObject {
    @Published var listElements: [ListElementEntity] = []
}
