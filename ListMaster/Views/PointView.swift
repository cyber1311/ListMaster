//
//  PointView.swift
//  ListMaster
//
//  Created by Анастасия Доблер on 15.03.2024.
//

import Foundation
import SwiftUI
import CoreData
import UserNotifications

struct PointView: View {
    @State private var showInternetErrorAlert = false
    @State private var showCommonErrorAlert = false
    
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @Binding var listElement: ListElementEntity
    @Binding var listElements: [ListElementEntity]
    @State private var listElementTitle: String = ""
    @State private var listElementDescription: String = ""
    @State private var listElementDeadline: Date = Date()
    @State private var listElementImagePath: String? = nil
    @State private var listElementCount: Int32 = 0
    @Binding var listTitle: String
    
    @State private var isDatePickerOn: Bool = false
    @State private var isImagePickerOn: Bool = false
    @State private var selectedImage: UIImage?
    @State private var isCompleted: Bool = false
  
    var body: some View {
        Form {
            Section(header: Text("Основная информация")) {
                TextField("Название", text: $listElementTitle)
                TextField("Описание", text: $listElementDescription)
                
                if listElement.count == 0, listElementCount == 0{
                    Button("Добавить количество"){
                        listElementCount = 1
                    }
                }else{
                    HStack(alignment: .center, content: {
                        Stepper("Количество: \(listElementCount)", value: $listElementCount, in: 1...1000000000)
                        Button(action: {
                            listElementCount = 0
                        }, label: {
                            Image(systemName: "trash")
                        })
                    })
                }
                
                if (listElement.deadline == nil && isDatePickerOn == false)
                || (listElement.deadline != nil && listElement.deadline!.compare(Date()) == .orderedAscending){
                    Button("Добавить дедлайн"){
                        isDatePickerOn = true
                    }
                }
                if isDatePickerOn || (listElement.deadline != nil && listElement.deadline!.compare(Date()) != .orderedAscending){
                    
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
            
            HStack(alignment: .center, content:
                    {
                
                Button {
                    if isCompleted == false{
                        isCompleted = true
                    }else{
                        isCompleted = false
                    }
                } label: {
                    Image(systemName: isCompleted ? "checkmark.square" : "square")
                        .imageScale(.large)
                        .foregroundColor(isCompleted ? .green : .black)
                }
                
                if isCompleted == true{
                    Text("Выполнено").foregroundColor(.green)
                }else{
                    Text("Не выполнено")
                }
            })
            .padding()

            Section {
                Button("Сохранить") {
                    listElement.title = listElementTitle
                    listElement.descriptionText = listElementDescription
                    if isDatePickerOn{
                        listElement.deadline = listElementDeadline
                    }
                    if isDatePickerOn == false && listElement.deadline != nil && listElementDeadline.compare(listElement.deadline!) == .orderedDescending{
                        listElement.deadline = listElementDeadline
                    }
                    listElement.imagePath = listElementImagePath
                    listElement.count = listElementCount
                    listElement.isDone = isCompleted
                    do {
                        try viewContext.save()
                        if let deadline = listElement.deadline {
                            scheduleNotification(for: deadline, withTitle: "Напоминание", andBody: "Дедлайн по задаче '\(listElement.title ?? "")'")
                        }
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
            self.listElementCount = self.listElement.count
            self.isCompleted = self.listElement.isDone
        }
        .alert(isPresented: $showInternetErrorAlert) {
            Alert(title: Text("Ошибка"), message: Text("Проверьте подключение к интернету"), dismissButton: .default(Text("OK")))
        }
        .alert(isPresented: $showCommonErrorAlert) {
            Alert(title: Text("Ошибка"), message: Text("Произошли технические неполадки"), dismissButton: .default(Text("OK")))
        }
        .navigationTitle(listElement.title!)
        
    }
    
    func updateElementsForServer(){
        do {
            let fetchRequest: NSFetchRequest<ListElementEntity> = ListElementEntity.fetchRequest()
                fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \ListElementEntity.createdAt, ascending: false)]
            fetchRequest.predicate = NSPredicate(format: "listId == %@", listElement.listId!.uuidString)
            
            listElements = try viewContext.fetch(fetchRequest)
            
            var elements = [ListElement]()
            for element in listElements {
                elements.append(ListElement(id: element.id!, title: element.title!, descriptionText: element.descriptionText, imagePath: element.imagePath, deadline: element.deadline, count: Int(element.count), isDone: element.isDone, createdAt: element.createdAt!))
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
    
    func scheduleNotification(for deadline: Date, withTitle title: String, andBody body: String) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            if settings.authorizationStatus == .authorized{
                let content = UNMutableNotificationContent()
                content.title = title
                content.body = body
                content.sound = UNNotificationSound.default

                let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: deadline)
                let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)

                let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

                UNUserNotificationCenter.current().add(request) { error in
                    if let error = error {
                        print("Error scheduling notification: \(error)")
                    }
                }
            }else{
                requestNotificationAuthorization()
            }
                
        }
        
    }
    
    func requestNotificationAuthorization() {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                if granted {
                    print("Разрешение на уведомления получено")
                } else {
                    print("Разрешение на уведомления отклонено или произошла ошибка: \(error?.localizedDescription ?? "")")
                }
            }
        }

}
