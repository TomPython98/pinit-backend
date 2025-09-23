import SwiftUI

struct DayForecast: View {
    let day: String
    let isStudyDay: Bool
    let high: Int
    let low: Int

    @State private var isExpanded = false

    var iconName: String {
        isStudyDay ? "book.fill" : "sun.max.fill"
    }

    var backgroundGradient: LinearGradient {
        isStudyDay ?
        LinearGradient(gradient: Gradient(colors: [Color.green.opacity(0.6), Color.blue.opacity(0.4)]), startPoint: .top, endPoint: .bottom) :
        LinearGradient(gradient: Gradient(colors: [Color.orange.opacity(0.6), Color.yellow.opacity(0.4)]), startPoint: .top, endPoint: .bottom)
    }

    var studyTip: String {
        switch day {
        case "Mon": return "Start the week strong! Prioritize your toughest tasks in the morning."
        case "Tue": return "Use the Pomodoro technique – study for 25 min, take a 5 min break."
        default: return "Keep up the good work!"
        }
    }

    var body: some View {
        VStack(spacing: 10) {
            Text(day)
                .font(.title.bold())
                .foregroundColor(.white)

            Image(systemName: iconName)
                .resizable()
                .scaledToFit()
                .frame(width: isExpanded ? 70 : 50, height: isExpanded ? 70 : 50)
                .foregroundColor(isExpanded ? .yellow : .white)
                .shadow(radius: 10)
                .animation(.spring(response: 0.5, dampingFraction: 0.5), value: isExpanded)

            if isExpanded {
                VStack {
                    Text("📌 \(studyTip)")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.5), value: isExpanded)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(backgroundGradient)
                .shadow(radius: 10)
        )
        .padding(.horizontal)
        .onTapGesture {
            withAnimation {
                isExpanded.toggle()
            }
        }
    }
}
