//
//  ImagePicker.swift
//  ListMaster
//
//  Created by Анастасия Доблер on 15.03.2024.
//

import Foundation
import PhotosUI
import SwiftUI
import CoreData

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    @Binding var image: UIImage?
    @Binding var imagePath: String?
    @Environment(\.presentationMode) private var presentationMode

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        var parent: ImagePicker

        init(parent: ImagePicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            if let itemProvider = results.first?.itemProvider, itemProvider.canLoadObject(ofClass: UIImage.self) {
                itemProvider.loadObject(ofClass: UIImage.self) { (image, error) in
                    if let uiImage = image as? UIImage {
                        DispatchQueue.main.async {
                            self.parent.image = uiImage
                            self.parent.saveImageToAppDirectory(uiImage)
                            self.parent.isPresented = false
                            self.parent.presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
            }
        }

        func pickerDidCancel(_ picker: PHPickerViewController) {
            self.parent.isPresented = false
            self.parent.presentationMode.wrappedValue.dismiss()
        }
    }

    func saveImageToAppDirectory(_ image: UIImage) {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }

        let filename = UUID().uuidString
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsDirectory.appendingPathComponent(filename)

        do {
            try data.write(to: fileURL)
            imagePath = filename
        } catch {
            print("Error saving image: \(error)")
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }

    func makeUIViewController(context: UIViewControllerRepresentableContext<ImagePicker>) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: UIViewControllerRepresentableContext<ImagePicker>) {}
}

