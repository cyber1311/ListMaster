//
//  ListDetailView.swift
//  ListMaster
//
//  Created by Анастасия Доблер on 15.03.2024.
//

import Foundation
import SwiftUI
import SDWebImageSwiftUI


struct ListDetailView: View {
    @State private var newListElement = ""
    @State private var newListTitle = ""
        
    @State private var showInternetErrorAlert = false
    @State private var showCommonErrorAlert = false
    
    @AppStorage("hideDone") private var hideDone: Bool = false

    @ObservedObject var viewModel: ListModel
    @State private var userId: UUID = UUID()
    @State private var token: String = ""
    @Environment(\.editMode) var editMode
    
    var body: some View {
        
        List {
            if viewModel.IsShared{
                if(viewModel.OwnerId != userId){
                    HStack{
                        NavigationLink(destination: ShareManagementView(listModel: viewModel)) {
                            Text("Общий доступ").foregroundStyle(.green).bold()
                        }
                        Spacer()
                    }
                }else{
                    HStack{
                        NavigationLink(destination: ShareManagementView(listModel: viewModel)) {
                            HStack {
                                Text("Управлять доступом").foregroundStyle(.green).bold()
                            }
                        }
                        Spacer()
                    }
                }
            }
            
            if editMode?.wrappedValue == .active{
                Section(header: Text("Изменить название списка")) {
                    HStack {
                        TextField(viewModel.Title, text: $newListTitle)
                        Button(action: {
                            if newListTitle != ""{
                                viewModel.Title = newListTitle
                                updateListTitleForServer()
                                newListTitle = ""
                            }
                            
                        }, label: {
                            Image(systemName: "checkmark.circle.fill")
                        })
                    }
                }
            }
            
            Toggle("Скрыть выполненное", isOn: $hideDone)
            
            Section(header: Text("Новый пункт")) {
                HStack {
                    TextField("Название", text: $newListElement)
                    Button(action: {
                        if newListElement != ""{
                            let listElem = ListElement(id: UUID(), title: self.newListElement, descriptionText: nil, imagePath: nil, reminder: nil, deadline: nil, count: 0, isDone: false, createdAt: Date())
                            viewModel.Elements.append(listElem)
                            self.newListElement = ""
                            updateForServer()
                            viewModel.sort()
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
            Section {
                ForEach($viewModel.Elements, id: \.Id) { element in
                    if hideDone == false || (hideDone == true && element.wrappedValue.IsDone == false){
                        HStack{
                            if element.wrappedValue.ImagePath != nil{
                                WebImage(url: URL(string: "http://localhost:5211/images/download?image_name=\(element.wrappedValue.ImagePath!)"))
                                    .resizable()
                                    .frame(width: 50, height: 50)
                                    .clipShape(Circle())
                            } else {
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 50, height: 50)
                            }
                            NavigationLink(destination: PointView(listElement: element, viewModel: viewModel)) {
                                if element.wrappedValue.IsDone == true{
                                    Text(element.wrappedValue.Title)
                                        .foregroundColor(.green)
                                        .strikethrough()
                                }else if element.wrappedValue.Deadline != nil && element.wrappedValue.Deadline!.compare(Date()) == .orderedAscending{
                                    Text(element.wrappedValue.Title)
                                        .foregroundColor(.red)
                                }else{
                                    Text(element.wrappedValue.Title)
                                }
                            }
                        }
                    }
                }
                .onDelete(perform: removeListElement)
            }
        }
        .toolbar {
            ToolbarItem {
                EditButton()
            }
                        
        }
        .onAppear{
            userId = UUID(uuidString: UserDefaults.standard.string(forKey: "UserId")!)!
            token = UserDefaults.standard.string(forKey: "Token")!
            viewModel.reload()
        }
        .onChange(of: hideDone) { newValue in
            UserDefaults.standard.set(newValue, forKey: "hideDone")
        }
        .navigationTitle(viewModel.Title)
        .refreshable{
            getList()
        }
    }
    
    func removeListElement(at offsets: IndexSet) {
        viewModel.Elements.remove(atOffsets: offsets)
        
        updateForServer()
    }
    
    func updateForServer(){
        do {
            
            let jsonElements = try JSONEncoder().encode(viewModel.Elements)
            let stringElements = String(data: jsonElements, encoding: .utf8)

            let listUpdateElementsRequest = ListUpdateElementsRequest(userId: userId, id: viewModel.Id, elements: stringElements!)

            let url = URL(string: "http://localhost:5211/lists/update_list_elements")!

            var request = URLRequest(url: url)
            request.httpMethod = "PUT"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("Bearer " + (token), forHTTPHeaderField: "Authorization")
            
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
 
            let listUpdateTitleRequest = ListUpdateTitleRequest(userId: userId, id: viewModel.Id, title: viewModel.Title)
            
            let url = URL(string: "http://localhost:5211/lists/update_list_title")!

            var request = URLRequest(url: url)
            request.httpMethod = "PUT"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("Bearer " + (token), forHTTPHeaderField: "Authorization")
            
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
    
    func getList (){
        let url = URL(string: "http://localhost:5211/lists/get_list?user_id=\(userId.uuidString.lowercased())&list_id=\(viewModel.Id.uuidString.lowercased())")!

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer " + (token), forHTTPHeaderField: "Authorization")

        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                showInternetErrorAlert = true
                print("Error: \(error)")
            } else if let data = data {
                do{
                    if let httpResponse = response as? HTTPURLResponse{
                        if httpResponse.statusCode == 200{
                            let decoder = JSONDecoder()

                            let list = try decoder.decode(ListResponse.self, from: data)
                            
                            if let elementsData = list.elements.data(using: .utf8) {
                                let elements = try decoder.decode([ListElement].self, from: elementsData)
                                DispatchQueue.main.async {
                                    self.viewModel.Id = list.id
                                    self.viewModel.Title = list.title
                                    self.viewModel.Elements = elements
                                    self.viewModel.IsShared = list.isShared
                                    self.viewModel.OwnerId = list.ownerId
                                    viewModel.reload()
                                }
                            }
                            
                            //showUserNotExistErrorAlert = false
                            showCommonErrorAlert = false
                            showInternetErrorAlert = false
//                        } else if httpResponse.statusCode == 404{
//                            print("Такого пользователя не существует")
//                            showUserNotExistErrorAlert = true
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
}
