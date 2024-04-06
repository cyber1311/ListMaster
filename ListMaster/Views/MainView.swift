//
//  MainView.swift
//  ListMaster
//
//  Created by Анастасия Доблер on 09.02.2024.
//

import SwiftUI

struct MainScreenView: View {
    @ObservedObject var my_lists: ListViewModel = ListViewModel()
    @State private var userId: UUID = UUID()
    @State private var token: String = ""
    @State private var newList = ""
    @State private var showInternetErrorAlert = false
    @State private var showCommonErrorAlert = false
    @State private var showUserNotExistErrorAlert = false
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
                            my_lists.lists.append(ListModel(id: listId, title: self.newList, elements: [], is_shared: false, owner_id: userId))
                            addListToServer(listId: listId)
                            self.newList = ""
                        }
                    }, label: {
                        Image(systemName: "plus.circle.fill")
                    })
                    
                }
            }
            Section(header: Text("Ваши списки")) {
                ForEach($my_lists.lists) { list in
                    NavigationLink(destination: ListDetailView(viewModel: list.wrappedValue)) {
                        Text(list.wrappedValue.Title)
                    }
                    .contextMenu(menuItems: {
                        Button(action: {
                            let newListId = UUID()
                            my_lists.lists.append(ListModel(id: newListId, title: list.wrappedValue.Title, elements: list.wrappedValue.Elements, is_shared: list.wrappedValue.IsShared, owner_id: list.wrappedValue.OwnerId))
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
                        ShareListView(listId: listToShare!)
                    }
                }
                .onDelete(perform: removeList)
                
                
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: ProfileView()) {
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
        .alert(isPresented: $showInternetErrorAlert) {
            Alert(title: Text("Ошибка"), message: Text("Проверьте подключение к интернету"), dismissButton: .default(Text("OK")))
        }
        .alert(isPresented: $showCommonErrorAlert) {
            Alert(title: Text("Ошибка"), message: Text("Произошли технические неполадки"), dismissButton: .default(Text("OK")))
        }
        .onAppear{
            userId = UUID(uuidString: UserDefaults.standard.string(forKey: "UserId")!)!
            token = UserDefaults.standard.string(forKey: "Token")!
            download()
            my_lists.reload()
        }
        .navigationTitle("Списки")
        .refreshable{
            download()
        }
    }
    
    func removeList(at offsets: IndexSet) {
        for index in offsets {
            let list = my_lists.lists[index]
            let listId = list.Id
            removeListFromServer(listId: listId)
        }
        my_lists.lists.remove(atOffsets: offsets)
        my_lists.reload()
    }
    
    func removeListFromServer(listId: UUID){
        let url = URL(string: "http://localhost:5211/lists/delete_list?user_id=\(userId.uuidString.lowercased())&id=\(listId.uuidString.lowercased())")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer " + (token), forHTTPHeaderField: "Authorization")
        
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
    
    }
    
    func addListToServer(listId: UUID){
        do {
            let url = URL(string: "http://localhost:5211/lists/add_list")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("Bearer " + (token), forHTTPHeaderField: "Authorization")
            let listModel = ListAddRequst(userId: userId, id: listId, title: newList, elements: "[]", is_shared: false, owner_id: userId)
            let jsonData = try JSONEncoder().encode(listModel)
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
                    showCommonErrorAlert = true
                    print("Some error")
                }
            }
            
            task.resume()
            my_lists.reload()
        } catch {
            print("Some error")
        }
        
        
    }
    
    func duplicateListToServer(listId: UUID, newListId: UUID){
        do {
            let url = URL(string: "http://localhost:5211/lists/duplicate_list")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("Bearer " + (token), forHTTPHeaderField: "Authorization")
            let listModel = ListDuplicateRequest(listId: listId, newListId: newListId, userId: userId)
            let jsonData = try JSONEncoder().encode(listModel)
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
                    showCommonErrorAlert = true
                    print("Some error")
                }
            }
            
            task.resume()
            my_lists.reload()
        } catch {
            print("Some error")
        }
        
        
    }
    
    func download (){
        my_lists.lists = []
        
        let url = URL(string: "http://localhost:5211/lists/get_all_user_lists?user_id=\(userId.uuidString.lowercased())")!

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

                            let lists = try decoder.decode([ListResponse].self, from: data)
                            
                            for list in lists {
                                if let elementsData = list.elements.data(using: .utf8) {
                                    let elements = try decoder.decode([ListElement].self, from: elementsData)
                                    DispatchQueue.main.async {
                                        my_lists.lists.append(ListModel(id: list.id, title: list.title, elements: elements, is_shared: list.isShared, owner_id: list.ownerId))
                                        my_lists.sort()
                                    }
                                }
                            }
                            DispatchQueue.main.async {
                                my_lists.sort()
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
    
    
}
