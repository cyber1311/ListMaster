//
//  PointView.swift
//  ListMaster
//
//  Created by Анастасия Доблер on 15.03.2024.
//

import Foundation
import SwiftUI
import UserNotifications
import SDWebImageSwiftUI

struct PointView: View {
    @State private var showErrorAlert = false
    @State private var alertMessage = ""
    
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @Binding var listElement: ListElement
    @ObservedObject var listModel: ListModel
    @State private var listElementTitle: String = ""
    @State private var listElementDescription: String = ""
    @State private var listElementReminder: Date = Date()
    @State private var listElementDeadline: Date = Date()
    @State private var listElementImagePath: String? = nil
    @State private var listElementCount: Int32 = 0
    
    @State private var isDeadlinePickerOn: Bool = false
    @State private var isReminderPickerOn: Bool = false
    @State private var isImagePickerOn: Bool = false
    @State private var selectedImage: UIImage?
    @State private var isCompleted: Bool = false
    @State var userInfo: UserInfo
  
    
    
    var body: some View {
        Form {
            Section(header: Text("Основная информация")) {
                TextField("Название", text: $listElementTitle)
                TextField("Описание:", text: $listElementDescription)
                
                if listElement.Count == 0, listElementCount == 0{
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
                
                if (listElement.Reminder == nil && isReminderPickerOn == false) || (listElement.Reminder != nil && listElement.Reminder!.compare(Date()) == .orderedAscending){
                    Button("Добавить напоминание"){
                        isReminderPickerOn = true
                    }
                }
                if isReminderPickerOn || (listElement.Reminder != nil && listElement.Reminder!.compare(Date()) != .orderedAscending){
                    VStack(alignment: .trailing){
                        DatePicker("Напомнить:", selection: $listElementReminder, in: Date()...)
                       
                        Button(action: {
                            isReminderPickerOn = false
                            listElement.Reminder = nil
                        }, label: {
                            HStack{
                                Text("Удалить")
                                Image(systemName: "trash")
                            }
                        })
                    }
                }
                
                
                if listElement.Deadline == nil && isDeadlinePickerOn == false{
                    Button("Добавить дедлайн"){
                        isDeadlinePickerOn = true
                    }
                }
                if listElement.Deadline != nil && listElement.Deadline!.compare(Date()) == .orderedAscending{
                    VStack(alignment: .trailing){
                        HStack{
                            Text("Дедлайн: ").foregroundColor(.red)
                            Spacer()
                            Text("\(formatDate(date: listElement.Deadline!))").foregroundColor(.red)
                        }
                        Button(action: {
                            listElement.Deadline = nil
                        }, label: {
                            HStack{
                                Text("Удалить").foregroundColor(.red)
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                        })
                    }
                }
                if isDeadlinePickerOn || (listElement.Deadline != nil && listElement.Deadline!.compare(Date()) != .orderedAscending){
                    VStack(alignment: .trailing){
                            DatePicker("Дедлайн:", selection: $listElementDeadline, in: Date()...)
                            Button(action: {
                                isDeadlinePickerOn = false
                                listElement.Deadline = nil
                            }, label: {
                                HStack{
                                    Text("Удалить")
                                    Image(systemName: "trash")
                                }
                            })
                    }
                    
                }
            
                if selectedImage == nil && listElement.ImagePath == nil{
                    Button("Добавить изображение"){
                        isImagePickerOn = true
                    }
                    if isImagePickerOn {
                        ImagePicker(isPresented: $isImagePickerOn, image: $selectedImage, imagePath: $listElementImagePath)
                    }
                }else{
                    if listElement.ImagePath != nil{
                        HStack(alignment: .center, content: {
                            WebImage(url: URL(string: "http://localhost:5211/images/download?image_name=\(listElement.ImagePath!)"))
                                .resizable()
                                .frame(width: 200, height: 200)
                                .clipShape(Circle())
                            Spacer()
                            VStack{
                                Spacer()
                                Spacer()
                                Button(action: {
                                    deleteImage(filename: listElement.ImagePath!)
                                    listElementImagePath = nil
                                    selectedImage = nil
                                    listElement.ImagePath = nil
                                }, label: {
                                    Image(systemName: "trash")
                                })
                            }
                        })
                        
                    }else if selectedImage != nil{
                        HStack(alignment: .center, content: {
                            Image(uiImage: selectedImage!)
                                .resizable()
                                .frame(width: 200, height: 200)
                                .clipShape(Circle())
                            Spacer()
                            VStack{
                                Spacer()
                                Spacer()
                                Button(action: {
                                    listElementImagePath = nil
                                    selectedImage = nil
                                    listElement.ImagePath = nil
                                }, label: {
                                    Image(systemName: "trash")
                                })
                            }
                        })
                    }
                }
            }
            
            
            Section{
                HStack(alignment: .center, content:
                        {
                    Button {
                        if isCompleted == false{
                            isCompleted = true
                            if listElement.Deadline != nil{
                                listElement.Deadline = nil
                            }
                        }else{
                            isCompleted = false
                        }
                    } label: {
                        Image(systemName: isCompleted ? "checkmark.square" : "square")
                            .imageScale(.large)
                            .foregroundColor(isCompleted ? .green : .black)
                    }
                    
                    if isCompleted == true{
                        Text("Выполнено").foregroundColor(.green).bold()
                    }else{
                        Text("Не выполнено")
                    }
                })
            }

            Section {
                HStack{
                    Spacer()
                    Button(action: {
                        listElement.Title = listElementTitle
                        if listElementDescription != ""{
                            listElement.DescriptionText = listElementDescription
                        }else{
                            listElement.DescriptionText = nil
                        }
                        if isDeadlinePickerOn {
                            listElement.Deadline = listElementDeadline
                        }
                        if isDeadlinePickerOn == false && listElement.Deadline != nil && listElementDeadline.compare(listElement.Deadline!) == .orderedDescending {
                            listElement.Deadline = listElementDeadline
                        }
                        
                        if isReminderPickerOn {
                            listElement.Reminder = listElementReminder
                        }
                        if isReminderPickerOn == false && listElement.Reminder != nil && listElementReminder.compare(listElement.Reminder!) == .orderedDescending {
                            listElement.Reminder = listElementReminder
                        }
                        
                        listElement.ImagePath = listElementImagePath
                        listElement.Count = Int(listElementCount)
                        listElement.IsDone = isCompleted
                        
                        if let deadline = listElement.Deadline {
                            scheduleNotification(for: deadline, withTitle: "Дедлайн", andBody: "Задача: '\(listElement.Title)'")
                        }
                        if let reminder = listElement.Reminder {
                            scheduleNotification(for: reminder, withTitle: "Напоминание", andBody: "Задача: '\(listElement.Title)'")
                        }
                        updateElementsForServer()
                        if selectedImage != nil &&  listElement.ImagePath != nil{
                            uploadImage(image: selectedImage!, filename: listElement.ImagePath!)
                        }
                        self.presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Сохранить")
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    Spacer()
                }
            }
        }
        .onAppear {
            self.listElementTitle = self.listElement.Title 
            self.listElementDescription = self.listElement.DescriptionText ?? ""
            self.listElementDeadline = self.listElement.Deadline ?? Date()
            self.listElementReminder = self.listElement.Reminder ?? Date()
            self.listElementImagePath = self.listElement.ImagePath
            self.listElementCount = Int32(self.listElement.Count)
            self.isCompleted = self.listElement.IsDone
        }
        .alert(isPresented: $showErrorAlert) {
            Alert(title: Text("Ошибка"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        
        .navigationTitle(listElement.Title)
        
    }
    
    func updateElementsForServer(){
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
    
    func formatDate(date: Date) -> String{
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.string(from: date)
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
    
    func uploadImage(image: UIImage, filename: String) {
        let url = URL(string: "http://localhost:5211/images/upload")!
        
        let boundary = UUID().uuidString
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        body.append(Data("--\(boundary)\r\n".utf8))
        body.append(Data("Content-Disposition: form-data; name=\"image\"; filename=\"\(filename)\"\r\n".utf8))
        body.append(Data("Content-Type: image/jpeg\r\n\r\n".utf8))
        
        if let imageData = image.jpegData(compressionQuality: 1.0) {
            body.append(imageData)
        }
        
        body.append(Data("\r\n".utf8))
        body.append(Data("--\(boundary)--\r\n".utf8))
        
        request.httpBody = body
        
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
    }

    
    func deleteImage(filename: String) {
        let url = URL(string: "http://localhost:5211/images/delete?image_name=\(filename)")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

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
    }
}
