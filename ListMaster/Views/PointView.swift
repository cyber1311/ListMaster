//
//  PointView.swift
//  ListMaster
//
//  Created by Анастасия Доблер on 15.03.2024.
//

import Foundation
import SwiftUI
import CoreData

struct PointView: View {
    @State private var showInternetErrorAlert = false
    @State private var showCommonErrorAlert = false
    
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @ObservedObject var listElement: ListElementEntity
    @Binding private var listElements: [ListElementEntity]
    @State private var listElementTitle: String = ""
    @State private var listElementDescription: String = ""
    @State private var listElementDeadline: Date = Date()
    @State private var listElementImagePath: String? = nil
    @State private var listTitle: String = ""
    
    @State private var isDatePickerOn: Bool = false
    @State private var isImagePickerOn: Bool = false
    @State private var selectedImage: UIImage?
    
    init(listElement: ListElementEntity, listElements: Binding<[ListElementEntity]>, listTitle: String){
        self.listElement = listElement
        self._listElements = listElements
        self.listTitle = listTitle
    }
    
    var body: some View {
        Form {
            Section(header: Text("Основная информация")) {
                TextField("Название", text: $listElementTitle)
                TextField("Описание", text: $listElementDescription)
                
                if listElement.deadline == nil, isDatePickerOn == false{
                    Button("Добавить дедлайн"){
                        isDatePickerOn = true
                    }
                }
                if isDatePickerOn || listElement.deadline != nil{
                    
                    HStack{
                        DatePicker("Дедлайн:", selection: $listElementDeadline, in: Date()...)
                        Spacer()
                        Button(action: {
                            isDatePickerOn = false
                            listElement.deadline = nil
                            
                        }, label: {
                            Image(systemName: "trash")
                        })
                    }
                    
                }
            
                if (selectedImage == nil && listElement.imagePath == nil){
                    Button("Добавить изображение"){
                        isImagePickerOn = true
                    }
                    if isImagePickerOn {
                        ImagePicker(isPresented: $isImagePickerOn, image: $selectedImage, imagePath: $listElementImagePath)
                    }
                }else{
                    if listElement.imagePath != nil, let uiImage = loadImageFromPath(imagePath: listElement.imagePath!){
                        HStack(alignment: .center, content: {
                            Image(uiImage: uiImage)
                                .resizable()
                                .frame(width: 200, height: 200)
                                .clipShape(Circle())
                            VStack{
                                Spacer()
                                Spacer()
                                Button(action: {
                                    listElementImagePath = nil
                                    selectedImage = nil
                                    listElement.imagePath = nil
                                    
                                }, label: {
                                    Image(systemName: "trash")
                                })
                            }
                        }).padding()
                        
                    }else if selectedImage != nil{
                        HStack(alignment: .center, content: {
                            Image(uiImage: selectedImage!)
                                .resizable()
                                .frame(width: 200, height: 200)
                                .clipShape(Circle())
                            VStack{
                                Spacer()
                                Spacer()
                                Button(action: {
                                    listElementImagePath = nil
                                    selectedImage = nil
                                    listElement.imagePath = nil
                                }, label: {
                                    Image(systemName: "trash")
                                })
                            }
                        }).padding()
                    }
                }
            }

            Section {
                Button("Сохранить") {
                    listElement.title = listElementTitle
                    listElement.descriptionText = listElementDescription
                    if isDatePickerOn{
                        listElement.deadline = listElementDeadline
                    }
                    listElement.imagePath = listElementImagePath
                    do {
                        try viewContext.save()
                        updateElementsForServer()
                        self.presentationMode.wrappedValue.dismiss()
                    } catch {
                        print("Ошибка сохранения изменений: \(error)")
                    }
                }
            }
        }
        .onAppear {
            self.listElementTitle = self.listElement.title ?? ""
            self.listElementDescription = self.listElement.descriptionText ?? ""
            self.listElementDeadline = self.listElement.deadline ?? Date()
            self.listElementImagePath = self.listElement.imagePath
        }
        .alert(isPresented: $showInternetErrorAlert) {
            Alert(title: Text("Ошибка"), message: Text("Проверьте подключение к интернету"), dismissButton: .default(Text("OK")))
        }
        .alert(isPresented: $showCommonErrorAlert) {
            Alert(title: Text("Ошибка"), message: Text("Произошли технические неполадки"), dismissButton: .default(Text("OK")))
        }.navigationTitle(listElement.title ?? "")
        
    }
    
    func updateElementsForServer(){
        do {
            let fetchRequest: NSFetchRequest<ListElementEntity> = ListElementEntity.fetchRequest()
                fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \ListElementEntity.createdAt, ascending: false)]
            fetchRequest.predicate = NSPredicate(format: "listId == %@", listElement.listId!.uuidString)
            
            listElements = try viewContext.fetch(fetchRequest)
            
            var elements = [ListElement]()
            for element in listElements {
                elements.append(ListElement(title: element.title!, descriptionText: element.descriptionText, imagePath: element.imagePath, deadline: element.deadline, count: Int(element.count), isDone: element.isDone))
            }
            let jsonElements = try JSONEncoder().encode(elements)
            let stringElements = String(data: jsonElements, encoding: .utf8)
            let userId = UUID(uuidString: UserDefaults.standard.string(forKey: "UserId") ?? "")
            
            
            let listUpdateElementsRequest = ListUpdateElementsRequest(userId: userId!, id: listElement.listId!, elements: stringElements!)
            
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
            print("Error fetching list elements: \(error)")
        }
    }
    
    func loadImageFromPath(imagePath: String) -> UIImage? {
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: imagePath) {
                if let imageData = fileManager.contents(atPath: imagePath) {
                    return UIImage(data: imageData)
                }
            }else{
                listElement.imagePath = nil
            }
            return nil
    }
    

}
