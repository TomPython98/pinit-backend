import SwiftUI

struct CalendarPopup: View {
    @Binding var selectedDate: Date
    @Binding var showCalendar: Bool

    var body: some View {
        VStack(spacing: 15) {
            Text("📅 Select a Date")
                .font(.headline)
                .foregroundColor(.white)

            DatePicker("", selection: $selectedDate, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .labelsHidden()
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.2)))
                .shadow(radius: 3)

            Text("📖 Study Plan: \(studyPlan(for: selectedDate))")
                .font(.subheadline)
                .foregroundColor(.yellow)
                .padding(.horizontal)
                .multilineTextAlignment(.center)

            Button(action: { withAnimation { showCalendar = false } }) {
                Text("Close")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red.opacity(0.8))
                    .cornerRadius(12)
                    .shadow(radius: 5)
            }
            .padding(.horizontal)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 15).fill(Color.black.opacity(0.9)))
        .shadow(radius: 10)
        .padding(.horizontal)
    }

    func studyPlan(for date: Date) -> String {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)

        switch weekday {
        case 2: return "📚 Focus on deep reading & notes!"
        case 3: return "📊 Revise key concepts & practice!"
        case 4: return "📝 Work on assignments & projects!"
        case 5: return "💡 Join a study group & discuss!"
        case 6: return "🎯 Take a mock test & review!"
        case 7: return "☀️ Light review & relax!"
        case 1: return "📖 Prepare for the upcoming week!"
        default: return "Keep up the good work!"
        }
    }
}
