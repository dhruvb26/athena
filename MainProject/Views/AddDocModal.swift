//
//  AddDocModal.swift
//  MainProject
//
//  Created by Kanav Gupta on 3/29/25.
//

import SwiftUI

struct AddDocModal: View {
    @State private var selectedSubject: String = ""
    @State private var selectedNotification: String = "AI Questions"
    @State private var showFileImporter = false
    @State private var fileURL: URL?
    
    let notificationTypes = ["AI Questions", "Snippets"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Add Subject Name")) {
                    TextField("eg: CSE 335",text: $selectedSubject)
                }
                
                Section(header: Text("Notification Type")) {
                    Picker("Notification", selection: $selectedNotification) {
                        ForEach(notificationTypes, id: \..self) { type in
                            Text(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text("Upload PDF")) {
                    Button(action: {
                        showFileImporter = true
                    }) {
                        HStack {
                            Image(systemName: "doc.fill")
                            Text(fileURL?.lastPathComponent ?? "Choose File")
                        }
                    }
                }
            }
            .navigationTitle("Add Document")
            .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [.pdf]) { result in
                switch result {
                case .success(let url):
                    fileURL = url
                case .failure(let error):
                    print("Error selecting file: \(error.localizedDescription)")
                }
            }
        }
    }
}

#Preview {
    AddDocModal()
}
