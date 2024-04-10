//
//  MainView.swift
//  ListMaster
//
//  Created by Анастасия Доблер on 09.02.2024.
//

import SwiftUI

struct MainScreenView: View {
    @ObservedObject var listModel: ListViewModel = ListViewModel()
    @State var userInfo: UserInfo = UserInfo()
    @State private var newList = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isShareListPresented = false
    @State private var listToShare: UUID? = nil
    
    var body: some View {
        List {
            Section(header: Text("Новый список")) {
                HStack {
                    TextField("Название", text: $newList)
                    Button(action: {
                        if newList != ""{
                            let listId = UUID()
                            listModel.lists.append(ListModel(id: listId, title: self.newList, elements: [], is_shared: false, owner_id: userInfo.UserId))
                            addListToServer(listId: listId)
                            self.newList = ""
                        }
                    }, label: {
                        Image(systemName: "plus.circle.fill")
                    })
                    
                }
            }
            Section(header: Text("Ваши списки")) {
                ForEach($listModel.lists) { list in
                    NavigationLink(destination: ListDetailView(listModel: list.wrappedValue, userInfo: userInfo)) {
                        Text(list.wrappedValue.Title)
                    }
                    .contextMenu(menuItems: {
                        Button(action: {
                            let newListId = UUID()
                            listModel.lists.append(ListModel(id: newListId, title: list.wrappedValue.Title, elements: list.wrappedValue.Elements, is_shared: list.wrappedValue.IsShared, owner_id: list.wrappedValue.OwnerId))
                            duplicateListToServer(listId: list.wrappedValue.Id, newListId: newListId)
                        }, label: {
                            HStack{
                                Text("Дублировать список")
                                Image(systemName: "doc.on.doc.fill")
                            }
                        })
                        Button(action: {
                            listToShare = list.wrappedValue.Id
                            isShareListPresented = true
                        }, label: {
                            HStack {
                                Text("Поделиться списком")
                                Image(systemName: "square.and.arrow.up")
                            }
                        })
                    })
                    .sheet(isPresented: Binding(
                        get: { isShareListPresented && listToShare != nil },
                        set: { _ in isShareListPresented = false }
                    )) {
                        ShareListView(listId: listToShare!, userInfo: userInfo)
                    }
                }
                .onDelete(perform: deleteList)
                
                
            }
        }
        
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: ProfileView(userInfo: userInfo)) {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 30, height: 30)
                        .foregroundColor(.blue)
                }
            }
            ToolbarItem {
                EditButton()
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Ошибка"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .onAppear{
            getAllUserLists()
            listModel.reload()
        }
        .navigationTitle("Списки")
        .refreshable{
            getAllUserLists()
        }
    }
    
    func deleteList(at offsets: IndexSet) {
        for index in offsets {
            let list = listModel.lists[index]
            let listId = list.Id
            deleteListFromServer(listId: listId)
        }
        listModel.lists.remove(atOffsets: offsets)
        listModel.reload()
    }
    
    func deleteListFromServer(listId: UUID){
        let url = URL(string: "http://localhost:5211/lists/delete_list?user_id=\(userInfo.UserId.uuidString.lowercased())&id=\(listId.uuidString.lowercased())")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer " + (userInfo.Token), forHTTPHeaderField: "Authorization")
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if data != nil {
                if let httpResponse = response as? HTTPURLResponse{
                    if httpResponse.statusCode == 404{
                        showAlert = true
                        alertMessage = "Список не найден"
                    }else if httpResponse.statusCode != 200{
                        DispatchQueue.main.async {
                            showAlert = true
                            alertMessage = "Произошли технические неполадки"
                        }
                    }
                }
            }else{
                DispatchQueue.main.async {
                    showAlert = true
                    alertMessage = "Произошли технические неполадки"
                }
            }
        }
        
        task.resume()
    
    }
    
    func addListToServer(listId: UUID){
        do {
            let url = URL(string: "http://localhost:5211/lists/add_list")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("Bearer " + (userInfo.Token), forHTTPHeaderField: "Authorization")
            let listAddRequst = ListAddRequst(userId: userInfo.UserId, id: listId, title: newList, elements: "[]", is_shared: false, owner_id: userInfo.UserId)
            let jsonData = try JSONEncoder().encode(listAddRequst)
            request.httpBody = jsonData
            
            let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                if data != nil {
                    if let httpResponse = response as? HTTPURLResponse{
                        if httpResponse.statusCode == 404{
                            showAlert = true
                            alertMessage = "Список не найден"
                        }else if httpResponse.statusCode != 200{
                            DispatchQueue.main.async {
                                showAlert = true
                                alertMessage = "Произошли технические неполадки"
                            }
                        }
                    }
                }else{
                    DispatchQueue.main.async {
                        showAlert = true
                        alertMessage = "Произошли технические неполадки"
                    }
                }
            }
            
            task.resume()
            listModel.reload()
        } catch {
            DispatchQueue.main.async {
                showAlert = true
                alertMessage = "Произошли технические неполадки"
            }
        }
        
        
    }
    
    func duplicateListToServer(listId: UUID, newListId: UUID){
        do {
            let url = URL(string: "http://localhost:5211/lists/duplicate_list")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("Bearer " + (userInfo.Token), forHTTPHeaderField: "Authorization")
            let listDuplicateRequest = ListDuplicateRequest(listId: listId, newListId: newListId, userId: userInfo.UserId)
            let jsonData = try JSONEncoder().encode(listDuplicateRequest)
            request.httpBody = jsonData
            
            let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                if data != nil {
                    if let httpResponse = response as? HTTPURLResponse{
                        if httpResponse.statusCode == 404{
                            showAlert = true
                            alertMessage = "Список не найден"
                        }else if httpResponse.statusCode != 200{
                            DispatchQueue.main.async {
                                showAlert = true
                                alertMessage = "Произошли технические неполадки"
                            }
                        }
                    }
                }else{
                    DispatchQueue.main.async {
                        showAlert = true
                        alertMessage = "Произошли технические неполадки"
                    }
                }
            }
            
            task.resume()
            listModel.reload()
        } catch {
            DispatchQueue.main.async {
                showAlert = true
                alertMessage = "Произошли технические неполадки"
            }
        }
        
        
    }
    
    func getAllUserLists (){
        listModel.lists = []
        
        let url = URL(string: "http://localhost:5211/lists/get_all_user_lists?user_id=\(userInfo.UserId.uuidString.lowercased())")!

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer " + (userInfo.Token), forHTTPHeaderField: "Authorization")

        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let data = data {
                do{
                    if let httpResponse = response as? HTTPURLResponse{
                        if httpResponse.statusCode == 200{
                            let decoder = JSONDecoder()

                            let lists = try decoder.decode([ListResponse].self, from: data)
                            
                            for list in lists {
                                if let elementsData = list.elements.data(using: .utf8) {
                                    let elements = try decoder.decode([ListElement].self, from: elementsData)
                                    DispatchQueue.main.async {
                                        listModel.lists.append(ListModel(id: list.id, title: list.title, elements: elements, is_shared: list.isShared, owner_id: list.ownerId))
                                        listModel.sort()
                                    }
                                }
                            }
                            DispatchQueue.main.async {
                                listModel.sort()
                            }
                        } else if httpResponse.statusCode == 404{
                            DispatchQueue.main.async {
                                showAlert = true
                                alertMessage = "Такого пользователя не существует"
                            }
                        } else {
                            DispatchQueue.main.async {
                                showAlert = true
                                alertMessage = "Произошли технические неполадки"
                            }
                        }
                    }
                }
                catch{
                    DispatchQueue.main.async {
                        showAlert = true
                        alertMessage = "Произошли технические неполадки"
                    }
                }
                
            }else{
                DispatchQueue.main.async {
                    showAlert = true
                    alertMessage = "Произошли технические неполадки"
                }
            }
        }
        
        task.resume()
    }
    
    
}
