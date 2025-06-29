import SwiftUI

struct AddTaskView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var title: String = ""
    let cropID: String
    let creatorName: String // Pass the current user's name or ID
    var onSave: (CropTask) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Task Title")) {
                    TextField("Enter task title", text: $title)
                }
            }
            .navigationBarTitle("Add Task", displayMode: .inline)
            .navigationBarItems(leading: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            }, trailing: Button("Save") {
                let newTask = CropTask(
                    title: title,
                    taskDescription: "", // Updated property name
                    dueDate: Date(),
                    isCompleted: false,
                    cropID: cropID
                )
                onSave(newTask)
                presentationMode.wrappedValue.dismiss()
            }.disabled(title.trimmingCharacters(in: .whitespaces).isEmpty))
        }
    }
} 