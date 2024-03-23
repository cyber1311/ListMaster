//
//  MainView.swift
//  ListMaster
//
//  Created by Анастасия Доблер on 09.02.2024.
//

import SwiftUI
import CoreData

struct MainScreenView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
            sortDescriptors: [NSSortDescriptor(keyPath: \ListEntity.title, ascending: true)],
            animation: .default)
    private var lists: FetchedResults<ListEntity>
    
    @State private var newList = ""
    @State private var showInternetErrorAlert = false
    @State private var showCommonErrorAlert = false
    
    var body: some View {
        NavigationView{
            List {
                Section(header: Text("Новый список")) {
                    HStack {
                        TextField("Название", text: $newList)
                        Button(action: {
                            if newList != ""{
                                do {
                                    let listId = UUID()
                                    addListToServer(listId: listId)
                                    let list = ListEntity(context: viewContext)
                                    list.id = listId
                                    list.title = self.newList
                                    try viewContext.save()
                                } catch {
                                    print("Some error")
                                }
                                self.newList = ""
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
                Section(header: Text("Ваши списки")) {
                    ForEach(lists) { list in
                        NavigationLink(destination: ListDetailView(listId: list.id!, listTitle: list.title!)) {
                            Text(list.title!)
                        }
                    }.onDelete(perform: removeList)
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
            .navigationTitle("Списки")
            
        }
    }
    
    func removeList(at offsets: IndexSet) {
        for index in offsets {
            do {
                let list = lists[index]
                let listId = list.id
                viewContext.delete(list)
                try self.viewContext.save()
                removeListFromServer(listId: listId!)
            } catch {
                print(error)
            }
        }
    }
    
    func removeListFromServer(listId: UUID){
        let userId = UUID(uuidString: UserDefaults.standard.string(forKey: "UserId") ?? "")
        let url = URL(string: "http://localhost:5211/lists/delete_list?user_id=\(userId!.uuidString.lowercased())&id=\(listId.uuidString.lowercased())")!
        print(url)
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let token = UserDefaults.standard.string(forKey: "Token")
        request.addValue("Bearer " + (token ?? ""), forHTTPHeaderField: "Authorization")
        
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
            let userId = UUID(uuidString: UserDefaults.standard.string(forKey: "UserId") ?? "")
            let token = UserDefaults.standard.string(forKey: "Token")
            request.addValue("Bearer " + (token ?? ""), forHTTPHeaderField: "Authorization")
            let listModel = ListModel(userId: userId!, id: listId, title: newList, elements: "")
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
                    print("Some error")
                }
            }
            
            task.resume()
        } catch {
            print("Some error")
        }
        
        
    }
    
    
}
