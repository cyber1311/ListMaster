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
        
    @State private var showErrorAlert = false
    @State private var alertMessage = ""
    
    @AppStorage("hideDone") private var hideDone: Bool = false

    @ObservedObject var listModel: ListModel
    @State var userInfo: UserInfo
    @Environment(\.editMode) var editMode
    
    var body: some View {
        
        List {
            if listModel.IsShared{
                if(listModel.OwnerId != userInfo.UserId){
                    HStack{
                        NavigationLink(destination: ShareManagementView(listModel: listModel, userInfo: userInfo)) {
                            Text("Общий доступ").foregroundStyle(.green).bold()
                        }
                        Spacer()
                    }
                }else{
                    HStack{
                        NavigationLink(destination: ShareManagementView(listModel: listModel, userInfo: userInfo)) {
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
                        TextField(listModel.Title, text: $newListTitle)
                        Button(action: {
                            if newListTitle != ""{
                                listModel.Title = newListTitle
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
                            listModel.Elements.append(listElem)
                            self.newListElement = ""
                            updateForServer()
                            listModel.sort()
                        }
                        
                    }, label: {
                        Image(systemName: "plus.circle.fill")
                    })
                    .alert(isPresented: $showErrorAlert) {
                        Alert(title: Text("Ошибка"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
                    }
                }
            }
            Section {
                ForEach($listModel.Elements, id: \.Id) { element in
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
                            NavigationLink(destination: PointView(listElement: element, listModel: listModel, userInfo: userInfo)) {
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
            listModel.reload()
        }
        .onChange(of: hideDone) { newValue in
            UserDefaults.standard.set(newValue, forKey: "hideDone")
        }
        .navigationTitle(listModel.Title)
        .refreshable{
            getList()
        }
    }
    
    func removeListElement(at offsets: IndexSet) {
        listModel.Elements.remove(atOffsets: offsets)
        
        updateForServer()
    }
    
    func updateForServer(){
        do {
            
            let jsonElements = try JSONEncoder().encode(listModel.Elements)
            let stringElements = String(data: jsonElements, encoding: .utf8)

            let listUpdateElementsRequest = ListUpdateElementsRequest(userId: userInfo.UserId, id: listModel.Id, elements: stringElements!)

            let url = URL(string: "http://localhost:5211/lists/update_list_elements")!

            var request = URLRequest(url: url)
            request.httpMethod = "PUT"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("Bearer " + (userInfo.Token), forHTTPHeaderField: "Authorization")
            
            let jsonData = try JSONEncoder().encode(listUpdateElementsRequest)
            request.httpBody = jsonData
            
            let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                if error != nil {
                    DispatchQueue.main.async {
                        showErrorAlert = true
                        alertMessage = "Произошли технические неполадки"
                    }
                } else if data != nil {
                    if let httpResponse = response as? HTTPURLResponse{
                        if httpResponse.statusCode != 200{
                            DispatchQueue.main.async {
                                showErrorAlert = true
                                alertMessage = "Произошли технические неполадки"
                            }
                        }
                    }
                    
                }else{
                    DispatchQueue.main.async {
                        showErrorAlert = true
                        alertMessage = "Произошли технические неполадки"
                    }
                }
            }
            
            task.resume()
            
        } catch {
            DispatchQueue.main.async {
                showErrorAlert = true
                alertMessage = "Произошли технические неполадки"
            }
        }
        
    }
    
    func updateListTitleForServer(){
        do{
 
            let listUpdateTitleRequest = ListUpdateTitleRequest(userId: userInfo.UserId, id: listModel.Id, title: listModel.Title)
            
            let url = URL(string: "http://localhost:5211/lists/update_list_title")!

            var request = URLRequest(url: url)
            request.httpMethod = "PUT"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("Bearer " + (userInfo.Token), forHTTPHeaderField: "Authorization")
            
            let jsonData = try JSONEncoder().encode(listUpdateTitleRequest)
            request.httpBody = jsonData
            
            let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                if error != nil {
                    DispatchQueue.main.async {
                        showErrorAlert = true
                        alertMessage = "Произошли технические неполадки"
                    }
                } else if data != nil {
                    if let httpResponse = response as? HTTPURLResponse{
                        if httpResponse.statusCode != 200{
                            DispatchQueue.main.async {
                                showErrorAlert = true
                                alertMessage = "Произошли технические неполадки"
                            }
                        }
                    }
                    
                }else{
                    DispatchQueue.main.async {
                        showErrorAlert = true
                        alertMessage = "Произошли технические неполадки"
                    }
                }
            }
            
            task.resume()
        }catch{
            DispatchQueue.main.async {
                showErrorAlert = true
                alertMessage = "Произошли технические неполадки"
            }
        }
    }
    
    func getList (){
        let url = URL(string: "http://localhost:5211/lists/get_list?user_id=\(userInfo.UserId.uuidString.lowercased())&list_id=\(listModel.Id.uuidString.lowercased())")!

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer " + (userInfo.Token), forHTTPHeaderField: "Authorization")

        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if error != nil {
                DispatchQueue.main.async {
                    showErrorAlert = true
                    alertMessage = "Произошли технические неполадки"
                }
            } else if let data = data {
                do{
                    if let httpResponse = response as? HTTPURLResponse{
                        if httpResponse.statusCode == 200{
                            let decoder = JSONDecoder()

                            let list = try decoder.decode(ListResponse.self, from: data)
                            
                            if let elementsData = list.elements.data(using: .utf8) {
                                let elements = try decoder.decode([ListElement].self, from: elementsData)
                                DispatchQueue.main.async {
                                    self.listModel.Id = list.id
                                    self.listModel.Title = list.title
                                    self.listModel.Elements = elements
                                    self.listModel.IsShared = list.isShared
                                    self.listModel.OwnerId = list.ownerId
                                    listModel.reload()
                                }
                            }
                            
                        } else if httpResponse.statusCode == 404{
                            DispatchQueue.main.async {
                                showErrorAlert = true
                                alertMessage = "Такого пользователя не существует"
                            }
                        } else {
                            DispatchQueue.main.async {
                                showErrorAlert = true
                                alertMessage = "Произошли технические неполадки"
                            }
                        }
                    }
                }
                catch{
                    DispatchQueue.main.async {
                        showErrorAlert = true
                        alertMessage = "Произошли технические неполадки"
                    }
                }
                
            }else{
                DispatchQueue.main.async {
                    showErrorAlert = true
                    alertMessage = "Произошли технические неполадки"
                }
            }
        }
        
        task.resume()
    }
}
