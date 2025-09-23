import SwiftUI

struct DateTimeSelector: View {
    @Binding var selectedDate: Date
    var title: String
    var minimumDate: Date? = nil
    
    // Format displayed date
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    // Store state for picker
    @State private var showPicker = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            Button(action: {
                withAnimation {
                    showPicker.toggle()
                }
            }) {
                HStack {
                    Text(dateFormatter.string(from: selectedDate))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "calendar")
                        .foregroundColor(.blue)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
            }
            
            if showPicker {
                VStack {
                    DatePicker("", selection: $selectedDate, in: (minimumDate ?? Date())..., displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(GraphicalDatePickerStyle())
                        .labelsHidden()
                    
                    Button("Done") {
                        withAnimation {
                            showPicker = false
                        }
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 30)
                    .background(Color.blue)
                    .cornerRadius(8)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                .padding(.top, 8)
            }
        }
    }
}

#Preview {
    VStack {
        DateTimeSelector(
            selectedDate: .constant(Date()),
            title: "Event Start Time",
            minimumDate: Date()
        )
        .padding()
    }
    .background(Color.gray.opacity(0.1))
} 